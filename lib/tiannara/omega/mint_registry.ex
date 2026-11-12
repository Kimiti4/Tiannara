defmodule Tiannara.Omega.MintRegistry do
  @moduledoc """
  Durable, append-only, integrity-protected registry of authorization grants and
  Council decision receipts (RL-565 / CP19.20, building on model M7).

  ## Why this exists

  `%Council.Authorization{}` and `%MachineAuthorization{}` are plain structs:
  any process can construct a structurally valid one. Effective authority
  therefore depends on a durable record written by an authenticated issuer.
  For machine authority the only accepted issuer is Council: a machine grant
  exists only when Council issued a one-time `DecisionReceipt` and that receipt
  was consumed atomically with the grant record.

  ## Record format (v2)

  Every physical record is

      {:tiannara_mint_registry, 2, seq, event, mac}

  where `seq` is a gap-free monotonic sequence starting at 1 and `mac` is
  HMAC-SHA256 over the canonical `{:tiannara_mint_registry, 2, seq, event}`
  payload using `config :tiannara, :mint_registry_integrity_key`. The key is
  provisioned outside the repository. A missing/short key makes the registry
  corrupt and every authority operation fails closed.

  Events:

    * `{:human_mint, id, ts, decision_ref | nil}` — human-path registration
    * `{:receipt_issue, receipt_map}` — Council receipt issuance (durable)
    * `{:machine_issue, machine_record}` — atomic receipt consumption + grant
    * `{:bind, id, effect_id, grant_digest | nil, ts}`
    * `{:consume, id, effect_id, ts}`

  ## Load verification (fail closed)

  On start and `reload/0` the entire file is decoded strictly. A truncated
  tail, an unknown/invalid term, a MAC failure, a sequence gap, a duplicate
  authorization or receipt, a machine grant without an issued receipt, a
  receipt consumed twice or by two grants, a bind/consume for an unknown or
  already-terminal grant, or a machine bind without a bound grant digest marks
  the whole registry corrupt. No prefix is promoted: corruption refuses all
  authority operations (`:registry_corrupt`) until an operator repairs or
  replaces the file.

  ## Concurrency

  All transitions are serialized through this GenServer. `issue_machine/3`
  checks the receipt is unconsumed, appends the grant record, and marks the
  receipt consumed in one durable append. `consume/2` is a compare-and-set of
  the single legal terminal transition; of N concurrent presentations exactly
  one receives `:ok`.

  ## Scope of this remediation

  Human-grant issuance (RL-564) remains a separate trust root. This module
  stores human records with the same integrity envelope but does not share a
  validator that accepts either proof: `verify_council_presentation/3` accepts
  only `issuer: :council` machine records. `record_bind/3` refuses machine
  records with `:authorization_provenance_invalid`; machine binding must go
  through `MachineAuthorization.bind_effect/2` -> `bind_machine/3`.
  """

  use GenServer
  require Logger

  alias Tiannara.Council.{DecisionDigest, DecisionReceipt, EmergencyState}

  @default_base "./data/dets"
  @registry_file "authorization_mint_registry.bin"
  @format_tag :tiannara_mint_registry
  @format_version 2
  @min_key_bytes 32

  @allowed_human_minters [
    Tiannara.Omega.HumanDelivery.Authorization,
    Tiannara.Omega.Verification.Baseline
  ]

  @type machine_record :: map()

  # ------------------------------------------------------------ client API --

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Absolute path of the registry file used by the running registry."
  @spec path() :: String.t() | :registry_unavailable
  def path, do: call(__MODULE__, :path)

  @doc """
  Rebuilds in-memory state from the durable file without restarting the
  process. This exercises the same strict loader used at boot and is the
  supported way to verify restart integrity inside a test node.
  """
  @spec reload() :: :ok | {:error, :registry_corrupt | :registry_unavailable}
  def reload, do: call(__MODULE__, :reload)

  @doc """
  Registers a freshly minted human-path grant. Machine authority must never use
  this function; `MachineAuthorization` uses `issue_machine/3` instead.
  """
  @spec record_mint(atom() | String.t(), keyword()) :: :ok | {:error, term()}
  def record_mint(authorization_id, opts \\ []) when is_list(opts) do
    call(__MODULE__, {:record_mint, authorization_id, Keyword.get(opts, :council_decision_ref)})
  end

  @doc """
  Legacy human-path binding. Machine records are refused with
  `{:error, :authorization_provenance_invalid}` because a caller-supplied id +
  effect + digest is not machine authority.
  """
  @spec record_bind(atom() | String.t(), String.t(), keyword()) ::
          :ok | {:error, term()} | :registry_unavailable | :registry_corrupt
  def record_bind(authorization_id, effect_id, opts \\ []) when is_list(opts) do
    call(
      __MODULE__,
      {:record_bind, authorization_id, effect_id, Keyword.get(opts, :council_decision_ref)}
    )
  end

  @doc """
  Durably records a Council-issued receipt so it cannot be replayed after a
  restart and so a later machine grant has a registry anchor.
  """
  @spec record_receipt(DecisionReceipt.t()) :: :ok | {:error, term()} | :registry_unavailable
  def record_receipt(%DecisionReceipt{} = receipt), do: call(__MODULE__, {:record_receipt, receipt})

  @doc "Registry status of a Council receipt."
  @spec receipt_status(String.t()) ::
          :issued | :consumed | :not_registered | :registry_corrupt | :registry_unavailable
  def receipt_status(receipt_id), do: call(__MODULE__, {:receipt_status, receipt_id})

  @doc """
  Atomically consumes a Council receipt and writes the machine grant record.
  Called only by `MachineAuthorization.mint/3` after receipt verification.
  """
  @spec issue_machine(map(), DecisionReceipt.t(), map()) ::
          :ok | {:error, term()} | :registry_unavailable | :registry_corrupt
  def issue_machine(grant, %DecisionReceipt{} = receipt, scope) when is_map(grant) do
    call(__MODULE__, {:issue_machine, grant, receipt, scope})
  end

  @doc """
  One-shot machine binding. Verifies the presented grant against the registry
  anchor and the exact effect scope, then records the binding and the bound
  grant digest.
  """
  @spec bind_machine(map(), String.t(), map()) ::
          :ok | {:error, term()} | :registry_unavailable | :registry_corrupt
  def bind_machine(grant, effect_id, scope) when is_map(grant) do
    call(__MODULE__, {:bind_machine, grant, effect_id, scope})
  end

  @doc """
  Effect-boundary verification for Council machine grants. The registry record,
  not a self-recomputed struct hash, is the authority.
  """
  @spec verify_council_presentation(map(), String.t(), map()) ::
          {:ok, machine_record()}
          | {:error, term()}
          | :registry_unavailable
          | :registry_corrupt
  def verify_council_presentation(grant, effect_id, scope) when is_map(grant) do
    call(__MODULE__, {:verify_council_presentation, grant, effect_id, scope})
  end

  @doc "Registry-anchored council decision digest for an authorization_id, or nil."
  @spec decision_ref(atom() | String.t()) ::
          String.t() | nil | :not_registered | :registry_unavailable | :registry_corrupt
  def decision_ref(authorization_id), do: call(__MODULE__, {:decision_ref, authorization_id})

  @doc "Registry-recorded binding for an authorization_id."
  @spec binding(atom() | String.t()) ::
          {:ok, String.t()} | :not_bound | :not_registered | :registry_unavailable | :registry_corrupt
  def binding(authorization_id), do: call(__MODULE__, {:binding, authorization_id})

  @doc "Current registry status of an authorization_id."
  @spec status(atom() | String.t()) ::
          :granted | :consumed | :not_registered | :registry_unavailable | :registry_corrupt
  def status(authorization_id), do: call(__MODULE__, {:status, authorization_id})

  @doc """
  Atomic terminal consumption, recording the bound effect_id. Machine records
  must be bound, unexpired, un-consumed and outside an active emergency.
  """
  @spec consume(atom() | String.t(), String.t() | nil) ::
          :ok | {:error, term()} | :registry_unavailable | :registry_corrupt
  def consume(authorization_id, effect_id), do: call(__MODULE__, {:consume, authorization_id, effect_id})

  @doc false
  @spec machine_record(atom() | String.t()) :: {:ok, machine_record()} | term()
  def machine_record(authorization_id), do: call(__MODULE__, {:machine_record, authorization_id})

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
    state = empty_state(path)

    case integrity_key() do
      {:ok, key} ->
        case load_state(%{state | key: key}) do
          {:ok, loaded} ->
            {:ok, loaded}

          {:error, reason} ->
            Logger.error("MintRegistry: integrity load failed (#{inspect(reason)}); failing closed")
            {:ok, corrupt_state(state)}
        end

      :error ->
        Logger.error("MintRegistry: integrity key unavailable; failing closed")
        {:ok, corrupt_state(state)}
    end
  end

  @impl true
  def handle_call(:path, _from, state), do: {:reply, state.path, state}

  def handle_call(:reload, _from, state) do
    case integrity_key() do
      {:ok, key} ->
        case load_state(%{state | key: key, corrupt: false}) do
          {:ok, loaded} -> {:reply, :ok, loaded}
          {:error, reason} ->
            Logger.error("MintRegistry: reload failed (#{inspect(reason)}); failing closed")
            {:reply, {:error, :registry_corrupt}, corrupt_state(state)}
        end

      :error ->
        {:reply, {:error, :registry_corrupt}, corrupt_state(state)}
    end
  end

  def handle_call({:record_mint, authorization_id, decision_ref}, from, state) do
    cond do
      state.corrupt ->
        {:reply, {:error, :registry_corrupt}, state}

      not minter_authorized?(from) ->
        {:reply, {:error, :minter_not_authorized}, state}

      Map.has_key?(state.statuses, authorization_id) ->
        {:reply, {:error, {:already_registered, authorization_id}}, state}

      not valid_id?(authorization_id) ->
        {:reply, {:error, :invalid_authorization_id}, state}

      not (is_nil(decision_ref) or digest?(decision_ref)) ->
        {:reply, {:error, :invalid_decision_ref}, state}

      true ->
        event = {:human_mint, authorization_id, now_unix(), decision_ref}

        case append_event(state, event) do
          {:ok, appended} ->
            updated =
              %{
                appended
                | statuses: Map.put(appended.statuses, authorization_id, :granted),
                  refs: Map.put(appended.refs, authorization_id, decision_ref),
                  kinds: Map.put(appended.kinds, authorization_id, :human)
              }

            {:reply, :ok, updated}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call({:record_receipt, %DecisionReceipt{} = receipt}, _from, state) do
    cond do
      state.corrupt ->
        {:reply, {:error, :registry_corrupt}, state}

      Map.has_key?(state.receipts, receipt.receipt_id) ->
        {:reply, {:error, {:already_registered, receipt.receipt_id}}, state}

      true ->
        with :ok <- DecisionReceipt.verify(receipt),
             false <- DecisionReceipt.expired?(receipt),
             {:ok, event} <- receipt_event(receipt),
             {:ok, appended} <- append_event(state, {:receipt_issue, event}) do
          record = Map.put(event, :status, :issued) |> Map.put(:authorization_id, nil)

          {:reply, :ok,
           %{appended | receipts: Map.put(appended.receipts, receipt.receipt_id, record)}}
        else
          true -> {:reply, {:error, :council_decision_receipt_expired}, state}
          {:error, reason} -> {:reply, {:error, reason}, state}
          :error -> {:reply, {:error, :registry_write_failed}, state}
        end
    end
  end

  def handle_call({:receipt_status, receipt_id}, _from, state) do
    reply =
      cond do
        state.corrupt -> :registry_corrupt
        record = state.receipts[receipt_id] -> record.status
        true -> :not_registered
      end

    {:reply, reply, state}
  end

  def handle_call({:issue_machine, grant, %DecisionReceipt{} = receipt, scope}, _from, state) do
    cond do
      state.corrupt ->
        {:reply, {:error, :registry_corrupt}, state}

      EmergencyState.active?() ->
        {:reply, {:error, :council_emergency_active}, state}

      true ->
        case validate_and_issue_machine(state, grant, receipt, scope) do
          {:ok, event} ->
            case append_event(state, {:machine_issue, event}) do
              {:ok, appended} ->
                {:reply, :ok, apply_machine_issue(appended, event)}

              {:error, reason} ->
                {:reply, {:error, reason}, state}
            end

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call({:bind_machine, grant, effect_id, scope}, _from, state) do
    cond do
      state.corrupt ->
        {:reply, {:error, :registry_corrupt}, state}

      EmergencyState.active?() ->
        {:reply, {:error, :council_emergency_active}, state}

      true ->
        case validate_and_bind_machine(state, grant, effect_id, scope) do
          {:ok, event} ->
            case append_event(state, event) do
              {:ok, appended} -> {:reply, :ok, apply_bind(appended, event)}
              {:error, reason} -> {:reply, {:error, reason}, state}
            end

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call({:verify_council_presentation, grant, effect_id, scope}, _from, state) do
    reply =
      if state.corrupt do
        {:error, :registry_corrupt}
      else
        verify_presentation(state, grant, effect_id, scope)
      end

    {:reply, reply, state}
  end

  def handle_call({:record_bind, authorization_id, effect_id, decision_ref}, _from, state) do
    cond do
      state.corrupt ->
        {:reply, {:error, :registry_corrupt}, state}

      not Map.has_key?(state.statuses, authorization_id) ->
        {:reply, {:error, :not_registered}, state}

      Map.get(state.kinds, authorization_id) == :machine ->
        {:reply, {:error, :authorization_provenance_invalid}, state}

      state.statuses[authorization_id] == :consumed ->
        {:reply, {:error, :already_consumed}, state}

      Map.has_key?(state.binds, authorization_id) ->
        {:reply, {:error, {:already_bound, state.binds[authorization_id]}}, state}

      anchor_mismatch?(state.refs[authorization_id], decision_ref) ->
        {:reply, {:error, :council_decision_mismatch}, state}

      true ->
        event =
          {:bind, authorization_id, effect_id, nil, now_unix()}

        case append_event(state, event) do
          {:ok, appended} -> {:reply, :ok, apply_bind(appended, event)}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call({:decision_ref, authorization_id}, _from, state) do
    reply =
      cond do
        state.corrupt -> :registry_corrupt
        not Map.has_key?(state.statuses, authorization_id) -> :not_registered
        true -> Map.get(state.refs, authorization_id)
      end

    {:reply, reply, state}
  end

  def handle_call({:binding, authorization_id}, _from, state) do
    reply =
      cond do
        state.corrupt -> :registry_corrupt
        not Map.has_key?(state.statuses, authorization_id) -> :not_registered
        bound = state.binds[authorization_id] -> {:ok, bound}
        true -> :not_bound
      end

    {:reply, reply, state}
  end

  def handle_call({:status, authorization_id}, _from, state) do
    reply =
      if state.corrupt do
        :registry_corrupt
      else
        Map.get(state.statuses, authorization_id, :not_registered)
      end

    {:reply, reply, state}
  end

  def handle_call({:machine_record, authorization_id}, _from, state) do
    reply =
      cond do
        state.corrupt -> {:error, :registry_corrupt}
        record = state.machines[authorization_id] -> {:ok, record}
        Map.has_key?(state.statuses, authorization_id) -> {:error, :authorization_provenance_invalid}
        true -> {:error, :authorization_not_registered}
      end

    {:reply, reply, state}
  end

  def handle_call({:consume, authorization_id, effect_id}, _from, state) do
    cond do
      state.corrupt ->
        {:reply, {:error, :registry_corrupt}, state}

      not Map.has_key?(state.statuses, authorization_id) ->
        {:reply, {:error, :not_registered}, state}

      state.statuses[authorization_id] == :consumed ->
        {:reply, {:error, :already_consumed}, state}

      Map.get(state.kinds, authorization_id) == :machine ->
        consume_machine(state, authorization_id, effect_id)

      # defense in depth: the consumed effect must match the registered binding
      Map.has_key?(state.binds, authorization_id) and
          state.binds[authorization_id] != effect_id ->
        {:reply, {:error, :registry_binding_mismatch}, state}

      true ->
        append_consume(state, authorization_id, effect_id)
    end
  end

  # ------------------------------------------------- machine validation ----

  defp validate_and_issue_machine(state, grant, receipt, scope) do
    case DecisionReceipt.verify(receipt) do
      :ok -> do_validate_and_issue_machine(state, grant, receipt, scope)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_validate_and_issue_machine(state, grant, receipt, scope) do
    receipt_id = Map.get(grant, :receipt_id)
    stored_receipt = state.receipts[receipt_id]
    receipt_digest = DecisionDigest.receipt(receipt)

    cond do
      not valid_grant_map?(grant) ->
        {:error, :authorization_provenance_invalid}

      is_nil(stored_receipt) ->
        {:error, :council_decision_receipt_invalid}

      stored_receipt.status != :issued ->
        {:error, :council_decision_receipt_consumed}

      stored_receipt.receipt_digest != receipt_digest ->
        {:error, :council_decision_receipt_invalid}

      Map.has_key?(state.statuses, grant.authorization_id) ->
        {:error, {:already_registered, grant.authorization_id}}

      stored_receipt.decision_digest != receipt.decision_digest or
          grant.council_decision_ref != receipt.decision_digest ->
        {:error, :council_decision_digest_mismatch}

      stored_receipt.decision_type != receipt.decision_type or
          grant.decision_type != receipt.decision_type ->
        {:error, :council_decision_type_mismatch}

      stored_receipt.scope_digest != receipt.scope_digest or
          grant.scope_digest != receipt.scope_digest or
          DecisionDigest.scope_digest(scope) != receipt.scope_digest ->
        {:error, :council_scope_mismatch}

      stored_receipt.actor != receipt.actor or grant.actor != receipt.actor ->
        {:error, :authorization_provenance_invalid}

      not digest?(DecisionDigest.machine_grant(grant)) ->
        {:error, :authorization_provenance_invalid}

      true ->
        {:ok, machine_record(grant, receipt, stored_receipt)}
    end
  rescue
    _ -> {:error, :authorization_provenance_invalid}
  end

  defp validate_and_bind_machine(state, grant, effect_id, scope) do
    id = Map.get(grant, :authorization_id)
    record = state.machines[id]

    cond do
      is_nil(record) ->
        {:error, :authorization_provenance_invalid}

      record.status == :consumed ->
        {:error, :already_consumed}

      record.effect_id != nil ->
        {:error, {:already_bound, record.effect_id}}

      EmergencyState.active?() ->
        {:error, :council_emergency_active}

      machine_expired?(record) ->
        {:error, :authorization_expired}

      receipt_not_consumed_by?(state, record) ->
        {:error, :authorization_provenance_invalid}

      record.grant_digest != DecisionDigest.machine_grant(grant) ->
        {:error, :authorization_grant_digest_mismatch}

      record.decision_digest != grant.council_decision_ref or
          record.decision_digest != DecisionDigest.decision(grant.decision) ->
        {:error, :council_decision_digest_mismatch}

      record.decision_type != grant.decision_type ->
        {:error, :council_decision_type_mismatch}

      DecisionDigest.scope_digest(scope) != record.scope_digest or
          grant.scope_digest != record.scope_digest ->
        {:error, :council_scope_mismatch}

      true ->
        bound_grant = Map.put(grant, :effect_id, effect_id)

        {:ok,
         {:bind, id, effect_id, DecisionDigest.machine_grant(bound_grant), now_unix()}}
    end
  rescue
    _ -> {:error, :authorization_provenance_invalid}
  end

  defp verify_presentation(state, grant, effect_id, scope) do
    id = Map.get(grant, :authorization_id)
    record = state.machines[id]

    cond do
      is_nil(record) and Map.has_key?(state.statuses, id) ->
        {:error, :authorization_provenance_invalid}

      is_nil(record) ->
        {:error, :authorization_not_registered}

      EmergencyState.active?() ->
        {:error, :council_emergency_active}

      record.status == :consumed ->
        {:error, :already_consumed}

      record.status != :bound ->
        {:error, :authorization_not_bound}

      machine_expired?(record) ->
        {:error, :authorization_expired}

      receipt_not_consumed_by?(state, record) ->
        {:error, :authorization_provenance_invalid}

      record.grant_digest != DecisionDigest.machine_grant(grant) ->
        {:error, :authorization_grant_digest_mismatch}

      record.decision_digest != grant.council_decision_ref or
          record.decision_digest != DecisionDigest.decision(grant.decision) ->
        {:error, :council_decision_digest_mismatch}

      record.decision_type != grant.decision_type ->
        {:error, :council_decision_type_mismatch}

      DecisionDigest.scope_digest(scope) != record.scope_digest or
          grant.scope_digest != record.scope_digest ->
        {:error, :council_scope_mismatch}

      record.effect_id != effect_id or Map.get(grant, :effect_id) != effect_id ->
        {:error, :registry_binding_mismatch}

      state.binds[id] != effect_id ->
        {:error, :registry_binding_mismatch}

      true ->
        {:ok, record}
    end
  rescue
    _ -> {:error, :authorization_provenance_invalid}
  end

  defp consume_machine(state, id, effect_id) do
    record = state.machines[id]

    cond do
      EmergencyState.active?() ->
        {:reply, {:error, :council_emergency_active}, state}

      is_nil(record) ->
        {:reply, {:error, :authorization_provenance_invalid}, state}

      record.status == :granted ->
        {:reply, {:error, :authorization_not_bound}, state}

      record.effect_id != effect_id or state.binds[id] != effect_id ->
        {:reply, {:error, :registry_binding_mismatch}, state}

      machine_expired?(record) ->
        {:reply, {:error, :authorization_expired}, state}

      receipt_not_consumed_by?(state, record) ->
        {:reply, {:error, :authorization_provenance_invalid}, state}

      true ->
        append_consume(state, id, effect_id)
    end
  end

  defp append_consume(state, id, effect_id) do
    event = {:consume, id, effect_id, now_unix()}

    case append_event(state, event) do
      {:ok, appended} ->
        {:reply, :ok,
         %{
           appended
           | statuses: Map.put(appended.statuses, id, :consumed),
             machines: mark_machine_consumed(appended.machines, id, effect_id)
         }}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp machine_record(grant, receipt, stored_receipt) do
    %{
      authorization_id: grant.authorization_id,
      issuer: :council,
      receipt_id: receipt.receipt_id,
      receipt_digest: stored_receipt.receipt_digest,
      decision_digest: receipt.decision_digest,
      grant_digest: DecisionDigest.machine_grant(grant),
      decision_type: receipt.decision_type,
      scope_digest: receipt.scope_digest,
      actor: receipt.actor,
      issuer_id: receipt.issuer,
      policy_version: receipt.policy_version,
      constitution_version: receipt.constitution_version,
      granted_at: grant.granted_at,
      ttl: grant.ttl,
      issued_at: receipt.issued_at,
      expires_at: DateTime.add(grant.granted_at, grant.ttl, :second),
      receipt_expires_at: receipt.expires_at,
      effect_id: nil,
      bound_at: nil,
      consumed_at: nil,
      status: :granted
    }
  end

  defp receipt_not_consumed_by?(state, record) do
    case state.receipts[record.receipt_id] do
      %{status: :consumed, authorization_id: id} -> id != record.authorization_id
      _ -> true
    end
  end

  defp machine_expired?(record) do
    case record do
      %{expires_at: %DateTime{} = expires_at} ->
        DateTime.compare(expires_at, DateTime.utc_now()) != :gt

      %{granted_at: %DateTime{} = granted_at, ttl: ttl} when is_integer(ttl) ->
        DateTime.diff(DateTime.utc_now(), granted_at) > ttl

      _ ->
        true
    end
  end

  defp mark_machine_consumed(machines, id, _effect_id) do
    case machines[id] do
      nil ->
        machines

      record ->
        Map.put(machines, id, %{record | status: :consumed, consumed_at: DateTime.utc_now()})
    end
  end

  # ------------------------------------------------------------- loader ----

  defp empty_state(path) do
    %{
      path: path,
      key: nil,
      corrupt: false,
      records: [],
      seq: 0,
      statuses: %{},
      binds: %{},
      refs: %{},
      kinds: %{},
      machines: %{},
      receipts: %{},
      grant_digests: %{}
    }
  end

  defp corrupt_state(state) do
    %{empty_state(state.path) | key: state.key, corrupt: true}
  end

  defp load_state(state) do
    case File.read(state.path) do
      {:ok, content} ->
        with {:ok, records} <- decode_records(content),
             {:ok, loaded} <- apply_records(state, records) do
          {:ok, %{loaded | records: records}}
        end

      {:error, :enoent} ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:registry_read_failed, reason}}
    end
  end

  defp decode_records(binary), do: do_decode(binary, [])

  defp do_decode(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp do_decode(<<size::32, term::binary-size(size), rest::binary>>, acc) do
    case safe_term(term) do
      {:ok, record} -> do_decode(rest, [record | acc])
      :error -> {:error, :invalid_record_term}
    end
  end

  defp do_decode(_truncated, _acc), do: {:error, :truncated_tail}

  defp safe_term(binary) do
    {:ok, :erlang.binary_to_term(binary, [:safe])}
  rescue
    _ -> :error
  end

  defp apply_records(state, records) do
    Enum.reduce_while(records, {:ok, state}, fn record, {:ok, acc} ->
      case apply_record(acc, record) do
        {:ok, next} -> {:cont, {:ok, next}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp apply_record(state, {:tiannara_mint_registry, 2, seq, event, mac}) do
    expected = state.seq + 1

    cond do
      seq != expected ->
        {:error, {:sequence_gap, expected, seq}}

      not is_binary(mac) ->
        {:error, :invalid_record_mac}

      not secure_compare(record_mac(state.key, seq, event), mac) ->
        {:error, {:record_mac_mismatch, seq}}

      true ->
        case apply_event(%{state | seq: seq}, event) do
          {:ok, next} -> {:ok, next}
          {:error, reason} -> {:error, {:event_invalid, seq, reason}}
        end
    end
  end

  defp apply_record(_state, other), do: {:error, {:invalid_record, other}}

  defp apply_event(state, {:human_mint, id, _ts, decision_ref}) do
    cond do
      not valid_id?(id) -> {:error, :invalid_authorization_id}
      Map.has_key?(state.statuses, id) -> {:error, :duplicate_authorization}
      not (is_nil(decision_ref) or digest?(decision_ref)) -> {:error, :invalid_decision_ref}
      true ->
        {:ok,
         %{
           state
           | statuses: Map.put(state.statuses, id, :granted),
             refs: Map.put(state.refs, id, decision_ref),
             kinds: Map.put(state.kinds, id, :human)
         }}
    end
  end

  defp apply_event(state, {:receipt_issue, receipt}) do
    cond do
      not valid_receipt_record?(receipt) ->
        {:error, :invalid_receipt_record}

      Map.has_key?(state.receipts, receipt.receipt_id) ->
        {:error, :duplicate_receipt}

      true ->
        record =
          receipt
          |> Map.put(:status, :issued)
          |> Map.put(:authorization_id, nil)

        {:ok, %{state | receipts: Map.put(state.receipts, receipt.receipt_id, record)}}
    end
  end

  defp apply_event(state, {:machine_issue, record}) do
    receipt = state.receipts[record.receipt_id]

    cond do
      not valid_machine_record?(record) ->
        {:error, :invalid_machine_record}

      Map.has_key?(state.statuses, record.authorization_id) ->
        {:error, :duplicate_authorization}

      is_nil(receipt) ->
        {:error, :machine_grant_without_receipt}

      receipt.status != :issued ->
        {:error, :receipt_consumed_twice}

      receipt.receipt_digest != record.receipt_digest or
          receipt.decision_digest != record.decision_digest or
          receipt.decision_type != record.decision_type or
          receipt.scope_digest != record.scope_digest or
          receipt.actor != record.actor or
          receipt.issuer != record.issuer_id or
          receipt.policy_version != record.policy_version or
          receipt.constitution_version != record.constitution_version ->
        {:error, :receipt_grant_mismatch}

      true ->
        consumed_receipt = %{receipt | status: :consumed, authorization_id: record.authorization_id}

        {:ok,
         %{
           state
           | statuses: Map.put(state.statuses, record.authorization_id, :granted),
             refs: Map.put(state.refs, record.authorization_id, record.decision_digest),
             kinds: Map.put(state.kinds, record.authorization_id, :machine),
             machines: Map.put(state.machines, record.authorization_id, record),
             receipts: Map.put(state.receipts, record.receipt_id, consumed_receipt),
             grant_digests: Map.put(state.grant_digests, record.authorization_id, record.grant_digest)
         }}
    end
  end

  defp apply_event(state, {:bind, id, effect_id, grant_digest, _ts}) do
    kind = state.kinds[id]
    machine = state.machines[id]

    cond do
      not Map.has_key?(state.statuses, id) -> {:error, :bind_unknown_authorization}
      state.statuses[id] == :consumed -> {:error, :bind_consumed_authorization}
      Map.has_key?(state.binds, id) -> {:error, :duplicate_bind}
      not is_binary(effect_id) -> {:error, :invalid_effect_id}
      kind == :machine and not digest?(grant_digest) -> {:error, :missing_grant_digest}
      kind == :machine and (is_nil(machine) or machine.status != :granted) -> {:error, :invalid_machine_bind}
      true ->
        binds = Map.put(state.binds, id, effect_id)
        grant_digests = if kind == :machine, do: Map.put(state.grant_digests, id, grant_digest), else: state.grant_digests

        machines =
          if kind == :machine do
            Map.put(state.machines, id, %{
              machine
              | status: :bound,
                effect_id: effect_id,
                bound_at: DateTime.utc_now(),
                grant_digest: grant_digest
            })
          else
            state.machines
          end

        {:ok, %{state | binds: binds, grant_digests: grant_digests, machines: machines}}
    end
  end

  defp apply_event(state, {:consume, id, effect_id, _ts}) do
    kind = state.kinds[id]
    machine = state.machines[id]

    cond do
      not Map.has_key?(state.statuses, id) -> {:error, :consume_unknown_authorization}
      state.statuses[id] == :consumed -> {:error, :double_consume}
      kind == :machine and (is_nil(machine) or machine.status != :bound) -> {:error, :consume_unbound_machine}
      state.binds[id] != nil and state.binds[id] != effect_id -> {:error, :consume_effect_mismatch}
      true ->
        machines =
          if kind == :machine do
            Map.put(state.machines, id, %{
              machine
              | status: :consumed,
                consumed_at: DateTime.utc_now()
            })
          else
            state.machines
          end

        {:ok,
         %{
           state
           | statuses: Map.put(state.statuses, id, :consumed),
             machines: machines
         }}
    end
  end

  defp apply_event(_state, event), do: {:error, {:unknown_event, event}}

  defp valid_receipt_record?(receipt) when is_map(receipt) do
    is_binary(Map.get(receipt, :receipt_id)) and
      is_binary(Map.get(receipt, :receipt_digest)) and
      digest?(Map.get(receipt, :decision_digest)) and
      is_atom(Map.get(receipt, :decision_type)) and
      digest?(Map.get(receipt, :scope_digest)) and
      is_binary(Map.get(receipt, :issuer)) and
      is_binary(Map.get(receipt, :policy_version)) and
      is_binary(Map.get(receipt, :constitution_version)) and
      is_struct(Map.get(receipt, :issued_at), DateTime) and
      is_struct(Map.get(receipt, :expires_at), DateTime)
  end

  defp valid_receipt_record?(_), do: false

  defp valid_machine_record?(record) when is_map(record) do
    valid_id?(Map.get(record, :authorization_id)) and
      Map.get(record, :issuer) == :council and
      is_binary(Map.get(record, :receipt_id)) and
      is_binary(Map.get(record, :receipt_digest)) and
      digest?(Map.get(record, :decision_digest)) and
      digest?(Map.get(record, :grant_digest)) and
      is_atom(Map.get(record, :decision_type)) and
      digest?(Map.get(record, :scope_digest)) and
      is_binary(Map.get(record, :issuer_id)) and
      is_binary(Map.get(record, :policy_version)) and
      is_binary(Map.get(record, :constitution_version)) and
      is_struct(Map.get(record, :granted_at), DateTime) and
      is_integer(Map.get(record, :ttl)) and
      Map.get(record, :status) == :granted and
      is_nil(Map.get(record, :effect_id))
  end

  defp valid_machine_record?(_), do: false

  defp valid_grant_map?(grant) when is_map(grant) do
    valid_id?(Map.get(grant, :authorization_id)) and
      is_binary(Map.get(grant, :receipt_id)) and
      digest?(Map.get(grant, :council_decision_ref)) and
      is_atom(Map.get(grant, :decision_type)) and
      digest?(Map.get(grant, :scope_digest)) and
      is_struct(Map.get(grant, :granted_at), DateTime) and
      is_integer(Map.get(grant, :ttl))
  end

  defp valid_grant_map?(_), do: false

  defp receipt_event(receipt) do
    {:ok,
     %{
       receipt_id: receipt.receipt_id,
       receipt_digest: DecisionDigest.receipt(receipt),
       decision_digest: receipt.decision_digest,
       decision_type: receipt.decision_type,
       scope_digest: receipt.scope_digest,
       actor: receipt.actor,
       issuer: receipt.issuer,
       policy_version: receipt.policy_version,
       constitution_version: receipt.constitution_version,
       issued_at: receipt.issued_at,
       expires_at: receipt.expires_at
     }}
  rescue
    _ -> {:error, :council_decision_receipt_invalid}
  end

  defp apply_machine_issue(state, record) do
    receipt = state.receipts[record.receipt_id]
    consumed_receipt = %{receipt | status: :consumed, authorization_id: record.authorization_id}

    %{
      state
      | statuses: Map.put(state.statuses, record.authorization_id, :granted),
        refs: Map.put(state.refs, record.authorization_id, record.decision_digest),
        kinds: Map.put(state.kinds, record.authorization_id, :machine),
        machines: Map.put(state.machines, record.authorization_id, record),
        receipts: Map.put(state.receipts, record.receipt_id, consumed_receipt),
        grant_digests: Map.put(state.grant_digests, record.authorization_id, record.grant_digest)
    }
  end

  defp apply_bind(state, {:bind, id, effect_id, grant_digest, _ts}) do
    kind = state.kinds[id]
    machine = state.machines[id]

    machines =
      if kind == :machine do
        Map.put(state.machines, id, %{
          machine
          | status: :bound,
            effect_id: effect_id,
            bound_at: DateTime.utc_now(),
            grant_digest: grant_digest
        })
      else
        state.machines
      end

    grant_digests =
      if kind == :machine, do: Map.put(state.grant_digests, id, grant_digest), else: state.grant_digests

    %{state | binds: Map.put(state.binds, id, effect_id), machines: machines, grant_digests: grant_digests}
  end

  # ------------------------------------------------------------ internals --

  defp append_event(state, event) do
    if state.corrupt or not is_binary(state.key) do
      {:error, :registry_corrupt}
    else
      seq = state.seq + 1
      mac = record_mac(state.key, seq, event)
      serialized = :erlang.term_to_binary({@format_tag, @format_version, seq, event, mac})

      result =
        try do
          File.write(state.path, [<<byte_size(serialized)::32>>, serialized], [:append])
        rescue
          error -> {:error, {:registry_write_failed, Exception.message(error)}}
        end

      case result do
        :ok ->
          {:ok, %{state | seq: seq, records: state.records ++ [event]}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp record_mac(key, seq, event) when is_binary(key) do
    payload = {@format_tag, @format_version, seq, event}

    :crypto.mac(:hmac, :sha256, key, :erlang.term_to_binary(payload, [:deterministic]))
    |> Base.encode16(case: :lower)
  end

  defp record_mac(_key, _seq, _event), do: ""

  defp integrity_key do
    case Application.get_env(:tiannara, :mint_registry_integrity_key) do
      key when is_binary(key) and byte_size(key) >= @min_key_bytes -> {:ok, key}
      _ -> :error
    end
  end

  defp valid_id?(id), do: is_atom(id) or is_binary(id)
  defp digest?(value), do: is_binary(value) and byte_size(value) == 64

  defp now_unix, do: System.system_time(:second)

  defp minter_authorized?({pid, _tag}) when is_pid(pid) do
    case Process.info(pid, :current_stacktrace) do
      {:current_stacktrace, frames} when is_list(frames) ->
        frames
        |> Enum.drop_while(fn frame -> frame_module(frame) in infra_stack_modules() end)
        |> case do
          [frame | _] -> frame_module(frame) in @allowed_human_minters
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

  defp secure_compare(left, right) when is_binary(left) and is_binary(right) do
    byte_size(left) == byte_size(right) and :crypto.hash_equals(left, right)
  end

  defp secure_compare(_left, _right), do: false
end
