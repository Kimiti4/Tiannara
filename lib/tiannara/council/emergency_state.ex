defmodule Tiannara.Council.EmergencyState do
  @moduledoc """
  Authoritative Council emergency snapshot.

  Stores the emergency state durably on disk (atomic replace + fsync) and
  mirrors it in `:persistent_term` for fast, VM-local reads.

  Durability contract:

    * `publish/1` persists first and only then updates the in-memory snapshot.
      A failed persist returns `{:error, reason}` and leaves memory untouched.
    * `load/0` fails closed. Corrupt or unreadable authoritative state returns
      `{:error, reason}` so callers (the Council supervisor) can refuse to
      start instead of silently defaulting to "not in emergency".
    * A missing state file is only treated as a first boot when the
      initialization marker is also absent. If the marker exists but the state
      file does not, the state is considered lost and `load/0` fails closed.

  A process-wide interlock (`with_interlock/1`) serializes emergency
  activation/lifting against protected world mutations, so an emergency cannot
  be activated between the final authorization check and the mutation.
  """

  @key {Tiannara.Council, :emergency_snapshot}
  @emergency_file "emergency_state.bin"
  @marker_file "emergency_state.initialized"

  @default %{
    active: false,
    invoked_by: nil,
    reason: nil,
    invoked_at: nil,
    epoch: 0
  }

  @emergency_allowed_decisions [:emergency_halt, :circuit_breaker]

  # ---------------------------------------------------------------- lifecycle

  @doc """
  Loads the authoritative emergency snapshot from disk.

  Returns `:ok` when a valid snapshot was loaded or a first-boot default was
  persisted. Returns `{:error, reason}` when authoritative state exists but is
  corrupt/unreadable, or when it is missing after initialization.
  """
  def load do
    state_path = path()
    marker_path = marker_path()

    case File.read(state_path) do
      {:ok, binary} ->
        case decode(binary) do
          {:ok, snapshot} ->
            :persistent_term.put(@key, snapshot)
            ensure_marker(marker_path)
            :ok

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :enoent} ->
        if File.exists?(marker_path) do
          {:error, :emergency_state_missing}
        else
          bootstrap(marker_path)
        end

      {:error, reason} ->
        {:error, {:emergency_state_unreadable, reason}}
    end
  end

  @doc """
  Publishes a new emergency snapshot.

  Persists durably first; only updates the in-memory snapshot after the write
  succeeds. Returns `:ok` or `{:error, reason}`.
  """
  def publish(%{active: active} = emergency) when is_boolean(active) do
    snapshot = Map.merge(@default, emergency)

    case persist(snapshot) do
      :ok ->
        :persistent_term.put(@key, snapshot)
        ensure_marker(marker_path())
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Returns the current in-memory emergency snapshot."
  def snapshot, do: :persistent_term.get(@key, @default)

  @doc "True when the Council is in an active constitutional emergency."
  def active?, do: match?(%{active: true}, snapshot())

  @doc "Monotonic emergency epoch (increments on invoke and lift)."
  def epoch, do: Map.get(snapshot(), :epoch, 0)

  def emergency_allowed_decisions, do: @emergency_allowed_decisions

  def decision_allowed?(decision_type), do: decision_type in @emergency_allowed_decisions

  def effect_allowed?(_operation), do: false

  # ---------------------------------------------------------------- interlock

  @doc """
  Runs `fun` while holding the shared emergency/effect interlock.

  Emergency activation and protected effect execution both acquire this lock,
  which makes the pair linearizable: either the effect completes before the
  emergency is published, or the emergency is published before the effect
  starts and the effect observes it and refuses.

  Returns the value of `fun`, or `{:error, :emergency_interlock_unavailable}` if
  the lock cannot be acquired (fail closed).
  """
  def with_interlock(fun) when is_function(fun, 0) do
    case :global.trans({{__MODULE__, :interlock}, self()}, fun, [node()], :infinity) do
      :aborted -> {:error, :emergency_interlock_unavailable}
      result -> result
    end
  end

  # ------------------------------------------------------------- test support

  @doc false
  def reset_test_state do
    if Application.get_env(:tiannara, :allow_test_receipt_signing, false) == true do
      :persistent_term.put(@key, @default)
      _ = File.rm(path())
      _ = File.rm(marker_path())
      :ok
    else
      {:error, :not_allowed}
    end
  end

  @doc false
  def clear_memory_for_test do
    if Application.get_env(:tiannara, :allow_test_receipt_signing, false) == true do
      :persistent_term.erase(@key)
      :ok
    else
      {:error, :not_allowed}
    end
  end

  @doc false
  def path do
    Path.join(base_path(), @emergency_file)
  end

  @doc false
  def marker_path do
    Path.join(base_path(), @marker_file)
  end

  # ------------------------------------------------------------- persistence

  defp base_path do
    case Application.get_env(:tiannara, :dets_base_path) do
      nil -> "./data/dets"
      v when is_binary(v) -> v
      v when is_list(v) -> List.to_string(v)
      v -> to_string(v)
    end
  end

  defp bootstrap(marker_path) do
    case persist(@default) do
      :ok ->
        :persistent_term.put(@key, @default)
        ensure_marker(marker_path)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp decode(binary) do
    try do
      decoded = :erlang.binary_to_term(binary, [:safe])

      cond do
        not is_map(decoded) ->
          {:error, :emergency_state_invalid}

        not is_boolean(Map.get(decoded, :active)) ->
          {:error, :emergency_state_invalid}

        not is_integer(Map.get(decoded, :epoch, 0)) ->
          {:error, :emergency_state_invalid}

        true ->
          {:ok, Map.merge(@default, decoded)}
      end
    rescue
      _ -> {:error, :emergency_state_corrupt}
    end
  end

  defp persist(snapshot) do
    target = path()
    dir = Path.dirname(target)
    tmp = target <> ".tmp"

    try do
      with :ok <- mkdir_p(dir),
           :ok <- File.write(tmp, :erlang.term_to_binary(snapshot, [:compressed]), [:sync]),
           :ok <- File.rename(tmp, target),
           :ok <- fsync_dir(dir) do
        :ok
      end
    rescue
      error -> {:error, {:emergency_persist_failed, Exception.message(error)}}
    after
      _ = File.rm(tmp)
    end
  end

  defp mkdir_p(dir) do
    case File.mkdir_p(dir) do
      :ok -> :ok
      {:error, reason} -> {:error, {:emergency_persist_failed, {:mkdir, reason}}}
    end
  end

  defp ensure_marker(marker_path) do
    case File.write(marker_path, "1", [:sync]) do
      :ok -> :ok
      {:error, reason} -> Logger.warning("emergency marker write failed: #{inspect(reason)}")
    end
  end

  # Directory entry durability is only meaningful on POSIX. On Windows opening
  # a directory for sync fails; that failure is non-fatal and ignored.
  defp fsync_dir(dir) do
    case :file.open(dir, [:read, :raw]) do
      {:ok, fd} ->
        _ = :file.sync(fd)
        _ = :file.close(fd)
        :ok

      {:error, _} ->
        :ok
    end
  end
end
