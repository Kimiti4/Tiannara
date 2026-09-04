Mix.Task.run("app.config")
Process.flag(:trap_exit, true)

[mode, out_dir] = System.argv()
File.mkdir_p!(out_dir)

attempt = fn f ->
  try do {:ok, f.()} rescue e -> {:error, "rescue: #{Exception.message(e)}"} catch kind, reason -> {:error, "exit #{inspect(kind)}: #{inspect(reason)}"} end
end

to_jsonable = fn to_jsonable, term ->
  case term do
    {:ok, v} -> %{"ok" => to_jsonable.(to_jsonable, v)}
    {:error, m} -> %{"error" => to_jsonable.(to_jsonable, m)}
    %{__struct__: _} = s -> to_jsonable.(to_jsonable, Map.from_struct(s))
    tuple when is_tuple(tuple) -> tuple |> Tuple.to_list() |> then(fn l -> to_jsonable.(to_jsonable, l) end)
    list when is_list(list) -> Enum.map(list, &to_jsonable.(to_jsonable, &1))
    map when is_map(map) -> Map.new(map, fn {k, v} -> {to_string(k), to_jsonable.(to_jsonable, v)} end)
    pid when is_pid(pid) -> inspect(pid)
    ref when is_reference(ref) -> inspect(ref)
    bool when is_boolean(bool) -> bool
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end

patch = fn path, replacements ->
  src = File.read!(path)
  Enum.reduce(replacements, src, fn {old, new}, acc ->
    if String.contains?(acc, old) do
      String.replace(acc, old, new, global: false)
    else
      raise "PATCH FAILED in #{Path.basename(path)}: #{String.slice(old, 0..80)}"
    end
  end)
end

# Candidate fix: foldl + honesty, replaces both traverse blocks
fix_lineage_old = "  def handle_call({:lineage, correlation_id}, _from, state) do\n    events =\n      :dets.traverse(@table_name, fn\n        {_event_id, %{correlation_id: cid} = ev, _offset} when cid == correlation_id ->\n          {:continue, ev}\n        _ ->\n          {:continue}\n      end)\n      |> Enum.sort_by(fn e -> e.timestamp end)\n\n    {:reply, events, state}\n  end"
fix_lineage_new = "  def handle_call({:lineage, correlation_id}, _from, state) do\n    result =\n      try do\n        :dets.foldl(fn\n          {_event_id, %{correlation_id: cid} = ev, _offset}, acc when cid == correlation_id -> [ev | acc]\n          _, acc -> acc\n        end, [], @table_name)\n      catch\n        _, _ -> {:error, :lineage_unavailable}\n      end\n\n    case result do\n      {:error, _} -> {:reply, {:error, :lineage_unavailable}, state}\n      events when is_list(events) ->\n        sorted = Enum.sort_by(events, fn e -> e.timestamp end)\n        {:reply, sorted, state}\n      _ -> {:reply, {:error, :lineage_unavailable}, state}\n    end\n  end"

fix_lessons_old = "  def handle_call({:find_lessons, tags}, _from, state) do\n    results =\n      :dets.traverse(@table_name, fn\n        {_event_id, %{event_type: :lesson, payload: %{tags: t}} = ev, _offset} ->\n          if Enum.any?(tags, &(&1 in t)) do\n            {:continue, ev}\n          else\n            {:continue}\n          end\n        _ ->\n          {:continue}\n      end)\n\n    {:reply, results, state}\n  end"
fix_lessons_new = "  def handle_call({:find_lessons, tags}, _from, state) do\n    result =\n      try do\n        :dets.foldl(fn\n          {_event_id, %{event_type: :lesson, payload: %{tags: t}} = ev, _offset}, acc ->\n            if Enum.any?(tags, &(&1 in t)) do\n              [ev | acc]\n            else\n              acc\n            end\n          _, acc -> acc\n        end, [], @table_name)\n      catch\n        _, _ -> {:error, :lineage_unavailable}\n      end\n\n    case result do\n      {:error, _} -> {:reply, {:error, :lineage_unavailable}, state}\n      results when is_list(results) -> {:reply, results, state}\n      _ -> {:reply, {:error, :lineage_unavailable}, state}\n    end\n  end"

result =
  case mode do
    "characterize" ->
      attempt.(fn ->
        # isolated topology: only EventStore + ExecutiveMemory (no full app)
        {:ok, _} = Supervisor.start_link([Tiannara.CEL.Services.EventStore, Tiannara.CEL.Services.ExecutiveMemory], strategy: :one_for_one, name: :ae006_char_sup)
        # ensure CIS not needed for this test
        # use a unique correlation_id for test lineage
        corr = "ae006_char_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
        # record a few events
        {:ok, _} = Tiannara.CEL.Services.ExecutiveMemory.record_event(:test_event, %{data: "a"}, %{correlation_id: corr})
        {:ok, _} = Tiannara.CEL.Services.ExecutiveMemory.record_event(:test_event, %{data: "b"}, %{correlation_id: corr})
        Process.sleep(200)

        # Normal lineage
        lineage_result = attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.get_lineage(corr) end)

        # Empty/no-match
        empty_result = attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.get_lineage("nonexistent_#{corr}") end)

        # Continuation leak check: check if any :continue in result
        has_continue = case lineage_result do
          {:ok, list} when is_list(list) -> Enum.any?(list, fn x -> x == :continue or x == {:continue} end)
          {:ok, {:error, _}} -> false
          _ -> false
        end

        # Check crash type
        crash_type = case lineage_result do
          {:error, msg} when is_binary(msg) ->
            cond do
              String.contains?(msg, "Enumerable") -> "Protocol.UndefinedError"
              String.contains?(msg, "continue") -> "continue_leak"
              true -> msg
            end
          _ -> "no_crash"
        end

        %{
          mode: "characterize",
          correlation_id: corr,
          lineage_result: lineage_result,
          empty_result: empty_result,
          has_continue_leak: has_continue,
          crash_type: crash_type,
          is_baseline_bug: String.contains?(inspect(lineage_result), "continue") or String.contains?(inspect(lineage_result), "Enumerable")
        }
      end)

    "candidate" ->
      attempt.(fn ->
        src = patch.("lib/tiannara/cel/services/executive_memory.ex", [
          {fix_lineage_old, fix_lineage_new},
          {fix_lessons_old, fix_lessons_new}
        ])
        Code.compile_string(src)

        # ensure isolated sup is clean
        if pid = Process.whereis(:ae006_char_sup) do
          Process.exit(pid, :kill)
          Process.sleep(300)
        end
        if pid = Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) do
          Process.exit(pid, :kill)
          Process.sleep(200)
        end
        if pid = Process.whereis(Tiannara.CEL.Services.EventStore) do
          Process.exit(pid, :kill)
          Process.sleep(200)
        end
        {:ok, _} = Supervisor.start_link([Tiannara.CEL.Services.EventStore, Tiannara.CEL.Services.ExecutiveMemory], strategy: :one_for_one, name: :ae006_cand_sup)
        Process.sleep(400)

        # Test data: use unique corr
        corr = "ae006_cand_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
        # Insert 100 events for lineage (large enough to test continuation, 5000 would be slow in chain)
        for i <- 1..100 do
          {:ok, _} = Tiannara.CEL.Services.ExecutiveMemory.record_event(:lesson, %{tags: [:test]}, %{correlation_id: corr})
          {:ok, _} = Tiannara.CEL.Services.ExecutiveMemory.record_event(:test_event, %{data: i}, %{correlation_id: corr})
        end
        Process.sleep(500)

        # Test 1: Normal Lineage
        lineage = Tiannara.CEL.Services.ExecutiveMemory.get_lineage(corr)
        t1_pass = is_list(lineage) and length(lineage) >= 100 and not Enum.any?(lineage, fn x -> x == :continue or x == {:continue} end)
        has_continue = is_list(lineage) and Enum.any?(lineage, fn x -> x == :continue or (is_tuple(x) and elem(x,0) == :continue) end)

        # Test 2: Empty/No-Match
        empty = Tiannara.CEL.Services.ExecutiveMemory.get_lineage("nonexistent_#{corr}")
        t2_pass = empty == []

        # Test 3: Continuation leak check on lessons (parity)
        lessons = Tiannara.CEL.Services.ExecutiveMemory.find_lessons([:test])
        t3_pass = is_list(lessons) and not Enum.any?(lessons, fn x -> x == :continue end)

        # Test 4: Recovery Honesty - must NOT mask corruption as empty list
        # Simulate by closing DETS; honest behavior is error, but even returning previous data is not masking as empty
        # The critical failure is returning [] when data is actually unavailable
        t4_result = attempt.(fn ->
          :dets.close(:cel_memory_v2)
          Process.sleep(100)
          res = Tiannara.CEL.Services.ExecutiveMemory.get_lineage(corr)
          # reopen for cleanup
          :dets.open_file(:cel_memory_v2, type: :set, file: ~c"./cel_memory_v2.dets")
          res
        end)
        t4_summary = case t4_result do
          {:ok, {:error, :lineage_unavailable}} -> %{type: "error_lineage_unavailable"}
          {:ok, {:error, _}} -> %{type: "error_other"}
          {:ok, []} -> %{type: "empty"}
          {:error, _} -> %{type: "crash"}
          {:ok, list} when is_list(list) -> %{type: "list", length: length(list)}
          _ -> %{type: "other"}
        end
        t4_pass = case t4_summary.type do
          "empty" -> false
          "crash" -> true
          "error_lineage_unavailable" -> true
          "error_other" -> true
          "list" -> true
          _ -> false
        end

        # Snapshot should still work (it uses traverse without skip) - summarize only
        snap_raw = attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.snapshot() end)
        snapshot = case snap_raw do
          {:ok, %{total_events: n}} -> %{ok: true, total_events: n}
          {:ok, _} -> %{ok: true}
          {:error, msg} -> %{ok: false, error: msg}
          other -> %{other: other}
        end

        %{
          mode: "candidate",
          normal_lineage: %{length: (if is_list(lineage), do: length(lineage), else: 0), pass: t1_pass, has_continue: has_continue},
          empty: %{value: (if empty == [], do: "empty", else: inspect(empty)), pass: t2_pass},
          lessons_parity: %{length: (if is_list(lessons), do: length(lessons), else: 0), pass: t3_pass},
          recovery_honesty: %{result: t4_summary, pass: t4_pass},
          snapshot: snapshot,
          overall_pass: t1_pass and t2_pass and t3_pass and t4_pass
        }
      end)
  end

IO.puts("AE006CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))
