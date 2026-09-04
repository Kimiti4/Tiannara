Process.flag(:trap_exit, true)

attempt = fn f ->
  try do
    {:ok, f.()}
  rescue
    e -> {:error, "rescue: #{Exception.message(e)}"}
  catch
    kind, reason -> {:error, "exit #{inspect(kind)}: #{inspect(reason)}"}
  end
end

result =
  attempt.(fn ->
    dlq_file = File.exists?("./cel_event_bus_dlq.dets")
    dlq_state = :dets.info(:cel_event_bus_dlq)
    {:ok, _} = Application.ensure_all_started(:tiannara)
    bus_registered = Process.whereis(Tiannara.CEL.Services.EventBus) != nil

    start_result =
      case Tiannara.CEL.Services.EventBus.start_link([]) do
        {:error, reason} -> {:start_error, reason}
        other -> other
      end

    %{
      dlq_file_exists_before: dlq_file,
      dlq_table_state_before: dlq_state,
      bus_registered_after_full_start: bus_registered,
      bus_start_result: start_result,
      dlq_state_after: :dets.info(:cel_event_bus_dlq)
    }
  end)

IO.puts("DIAG_RESULT " <> Jason.encode!(result))