defmodule Tiannara.Omega.MintRegistry do
  @moduledoc """
  Durable, append-only registry of minted authorization grants (model M7;
  enforced by the governed sink as gates N8/N9).

  WHY THIS EXISTS (anti-forgery, D127.6): `Authorization` grants are plain
  structs — any process can construct a structurally valid one without ever
  minting through the human path. Struct-shape trust is therefore insufficient.
  This registry makes EFFECTIVE authorization depend on a durable mint record:
  an authorization_id that was never registered, or was already consumed, is
  refused at the sink regardless of how valid the struct looks.

  CONCURRENCY (M4/G6, D127.1/D127.2): all state transitions are serialized
  through this GenServer. `consume/2` is a compare-and-set of the single legal
  transition granted -> consumed; of N concurrent presentations of one grant,
  exactly one receives `:ok` and the rest receive `{:error, :already_consumed}`.

   DURABILITY: records are appended to a size-prefixed binary file (same record
   format as `DeploymentRegistry`), one `{:mint, id, ts, council_decision_ref}`
   event per registration (legacy 3-tuples load with a `nil` ref), one
   `{:bind, id, effect_id, ts}` event per effect binding, and one
   `{:consume, id, effect_id, ts}` event per consumption. The in-memory status,
   binding and decision-ref maps are rebuilt from this file on start, so
   bindings, consumption and anchors survive a restart. The file lives under
   `:dets_base_path` (per-run isolated in tests).

  BINDING ANTI-TAMPER: the one-shot binding is recorded here, not only in the
  grant struct. A struct whose `effect_id` field is rewritten after binding
  disagrees with this registry and is refused at the sink
  (`:registry_binding_mismatch`) — plain-struct mutation is not sufficient to
  re-point an authorization at a different effect.

   FAIL-CLOSED: if this registry is not running or its file cannot be appended,
   the sink refuses to execute (`:authorization_registry_unavailable`) — an
   unavailable registry never permits an effect. A corrupt file loads as empty,
   which refuses previously registered grants (fail-closed) rather than
   admitting them.

   MINTER AUTHENTICATION (step-13, R-2): `record_mint/2` refuses callers whose
   call-stack origin module is not in the minter allowlist — minting is no
   longer open to any in-node process. The check inspects the blocked caller's
   stack (`GenServer.call` frames between the caller and this registry); an
   unresolvable stack refuses (`:minter_not_authorized`, fail-closed). This
   authenticates the ORIGINATING MODULE of the call inside the node; it is not
   a cryptographic capability and says nothing about a process that has already
   subverted an allowlisted module (in-node trusted-code boundary).

   DECISION ANCHORING (step-13, R-1): machine mints record a
   `council_decision_ref` digest of the council decision payload. The digest is
   compared at bind — a struct whose decision was rewritten and rehashed
   cannot match the registry-anchored copy (`:council_decision_mismatch`).
   Grants registered without a ref (human path, legacy records) bind only
   against an equally ref-less presented struct.

   Constitutional basis: Safety and Reliability, "Capability must never
   outpace verification", "Maintain audit trails".
   """

  use GenServer
  require Logger

  @default_base "./data/dets"
  @registry_file "authorization_mint_registry.bin"

  @allowed_minters [
    Tiannara.Council.MachineAuthorization,
    Tiannara.Omega.HumanDelivery.Authorization,
    Tiannara.Omega.Verification.Baseline
  ]

  # ------------------------------------------------------------ client API --

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a freshly minted grant. Fails if the id is already registered
  (a second registration of the same id is treated as a forgery attempt).
  The calling process's stack origin must be an allowlisted minter module
  (R-2) or the call is refused `{:error, :minter_not_authorized}`.
  Options: `:council_decision_ref` — digest anchored in this registry (R-1).
  """
  @spec record_mint(atom() | String.t(), keyword()) :: :ok | {:error, term()}
  def record_mint(authorization_id, opts \\ []) when is_list(opts) do
    call(__MODULE__, {:record_mint, authorization_id, Keyword.get(opts, :council_decision_ref)})
  end

  @doc """
  Records the one-shot effect binding for a registered, unconsumed grant.
  Mirrors `Authorization.bind_effect/2`: a second binding of the same id is
  refused with `{:error, {:already_bound, existing}}`. When this grant was
  minted with a `council_decision_ref`, the presented ref must match the
  registry-anchored copy (R-1) or the bind is refused
  `{:error, :council_decision_mismatch}`.
  """
  @spec record_bind(atom() | String.t(), String.t(), keyword()) ::
          :ok | {:error, term()} | :registry_unavailable
  def record_bind(authorization_id, effect_id, opts \\ []) when is_list(opts) do
    call(__MODULE__, {:record_bind, authorization_id, effect_id, Keyword.get(opts, :council_decision_ref)})
  end

  @doc "Registry-anchored council decision digest for an authorization_id, or nil."
  @spec decision_ref(atom() | String.t()) :: String.t() | nil | :not_registered | :registry_unavailable
  def decision_ref(authorization_id) do
    call(__MODULE__, {:decision_ref, authorization_id})
  end

  @doc "Registry-recorded binding for an authorization_id."
  @spec binding(atom() | String.t()) ::
          {:ok, String.t()}
          | :not_bound
          | :not_registered
          | :registry_unavailable
  def binding(authorization_id) do
    call(__MODULE__, {:binding, authorization_id})
  end

  @doc "Current registry status of an authorization_id."
  @spec status(atom() | String.t()) :: :granted | :consumed | :not_registered | :registry_unavailable
  def status(authorization_id) do
    call(__MODULE__, {:status, authorization_id})
  end

  @doc """
  Atomic granted -> consumed CAS, recording the bound effect_id. The ONLY
  transition out of `:granted` in this registry.
  """
  @spec consume(atom() | String.t(), String.t() | nil) ::
          :ok
          | {:error, :already_consumed | :not_registered}
          | :registry_unavailable
  def consume(authorization_id, effect_id) do
    call(__MODULE__, {:consume, authorization_id, effect_id})
  end

  defp call(server, request) do
    if Process.whereis(server) do
      GenServer.call(server, request)
    else
      :registry_unavailable
    end
  catch
    :exit, _ -> :registry_unavailable
  end

  # ---------------------------------------------------------- server (OTP) --

  @impl true
  def init(opts) do
    path =
      Keyword.get_lazy(opts, :path, fn ->
        base = Application.get_env(:tiannara, :dets_base_path, @default_base)
        Path.join(base, @registry_file)
      end)

    File.mkdir_p!(Path.dirname(path))
    {statuses, binds, refs} = load_state(path)

    if statuses == %{} and file_non_empty?(path) do
      Logger.error("MintRegistry: registry file unreadable/corrupt, loading empty (fail-closed)")
    end

    {:ok, %{path: path, statuses: statuses, binds: binds, refs: refs}}
  end

  @impl true
  def handle_call({:record_mint, authorization_id, decision_ref}, from, state) do
    cond do
      not minter_authorized?(from) ->
        {:reply, {:error, :minter_not_authorized}, state}

      Map.has_key?(state.statuses, authorization_id) ->
        {:reply, {:error, {:already_registered, authorization_id}}, state}

      true ->
        append_and_reply(
          state,
          {:mint, authorization_id, System.system_time(:second), decision_ref},
          fn state ->
            %{
              state
              | statuses: Map.put(state.statuses, authorization_id, :granted),
                refs: Map.put(state.refs, authorization_id, decision_ref)
            }
          end
        )
    end
  end

  def handle_call({:record_bind, authorization_id, effect_id, decision_ref}, _from, state) do
    cond do
      not Map.has_key?(state.statuses, authorization_id) ->
        {:reply, {:error, :not_registered}, state}

      state.statuses[authorization_id] == :consumed ->
        {:reply, {:error, :already_consumed}, state}

      Map.has_key?(state.binds, authorization_id) ->
        {:reply, {:error, {:already_bound, state.binds[authorization_id]}}, state}

      anchor_mismatch?(state.refs[authorization_id], decision_ref) ->
        {:reply, {:error, :council_decision_mismatch}, state}

      true ->
        append_and_reply(
          state,
          {:bind, authorization_id, effect_id, System.system_time(:second)},
          fn state -> %{state | binds: Map.put(state.binds, authorization_id, effect_id)} end
        )
    end
  end

  def handle_call({:decision_ref, authorization_id}, _from, state) do
    reply =
      cond do
        not Map.has_key?(state.statuses, authorization_id) -> :not_registered
        true -> Map.get(state.refs, authorization_id)
      end

    {:reply, reply, state}
  end

  def handle_call({:binding, authorization_id}, _from, state) do
    reply =
      cond do
        not Map.has_key?(state.statuses, authorization_id) -> :not_registered
        bound = state.binds[authorization_id] -> {:ok, bound}
        true -> :not_bound
      end

    {:reply, reply, state}
  end

  def handle_call({:status, authorization_id}, _from, state) do
    {:reply, Map.get(state.statuses, authorization_id, :not_registered), state}
  end

  def handle_call({:consume, authorization_id, effect_id}, _from, state) do
    cond do
      not Map.has_key?(state.statuses, authorization_id) ->
        {:reply, {:error, :not_registered}, state}

      state.statuses[authorization_id] == :consumed ->
        {:reply, {:error, :already_consumed}, state}

      # defense in depth: the consumed effect must match the registered binding
      Map.has_key?(state.binds, authorization_id) and
          state.binds[authorization_id] != effect_id ->
        {:reply, {:error, :registry_binding_mismatch}, state}

      true ->
        append_and_reply(
          state,
          {:consume, authorization_id, effect_id, System.system_time(:second)},
          fn state -> %{state | statuses: Map.put(state.statuses, authorization_id, :consumed)} end
        )
    end
  end

  # ------------------------------------------------------------- internals --

  defp minter_authorized?({pid, _tag}) when is_pid(pid) do
    case Process.info(pid, :current_stacktrace) do
      {:current_stacktrace, frames} when is_list(frames) ->
        frames
        |> Enum.drop_while(fn frame -> frame_module(frame) in infra_stack_modules() end)
        |> case do
          [frame | _] -> frame_module(frame) in @allowed_minters
          [] -> false
        end

      _ ->
        false
    end
  end

  defp minter_authorized?(_), do: false

  defp frame_module({module, _function, _args_or_arity}), do: module
  defp frame_module({module, _function, _args_or_arity, _location}), do: module
  defp frame_module(_), do: nil

  defp infra_stack_modules, do: [GenServer, Kernel, :erlang, :gen_server, :gen, __MODULE__]

  defp anchor_mismatch?(stored, presented) do
    not (is_nil(stored) and is_nil(presented)) and stored != presented
  end

  defp append_and_reply(state, record, update) do
    case append_record(state.path, record) do
      :ok -> {:reply, :ok, update.(state)}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp append_record(path, record) do
    serialized = :erlang.term_to_binary(record)

    try do
      File.write(path, [<<byte_size(serialized)::32>>, serialized], [:append])
    rescue
      error -> {:error, {:registry_write_failed, Exception.message(error)}}
    end
    |> case do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_state(path) do
    case File.read(path) do
      {:ok, content} ->
        content |> decode_records() |> Enum.reduce({%{}, %{}, %{}}, &apply_record/2)

      _ ->
        {%{}, %{}, %{}}
    end
  end

  defp apply_record({:mint, id, _ts}, {statuses, binds, refs}),
    do: {Map.put_new(statuses, id, :granted), binds, Map.put_new(refs, id, nil)}

  defp apply_record({:mint, id, _ts, decision_ref}, {statuses, binds, refs}),
    do: {Map.put_new(statuses, id, :granted), binds, Map.put_new(refs, id, decision_ref)}

  defp apply_record({:bind, id, effect_id, _ts}, {statuses, binds, refs}),
    do: {statuses, Map.put_new(binds, id, effect_id), refs}

  defp apply_record({:consume, id, _effect_id, _ts}, {statuses, binds, refs}),
    do: {Map.put(statuses, id, :consumed), binds, refs}

  defp apply_record(_other, acc), do: acc

  defp decode_records(<<>>), do: []

  defp decode_records(<<size::32, term::binary-size(size), rest::binary>>) do
    [:erlang.binary_to_term(term) | decode_records(rest)]
  end

  defp decode_records(_truncated), do: []

  defp file_non_empty?(path) do
    case File.stat(path) do
      {:ok, %{size: size}} when size > 0 -> true
      _ -> false
    end
  end
end
