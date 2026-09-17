defmodule TiannaraRuntime.WorldModel.ModelRegistry do
  @moduledoc """
  Phase 17.1 — ModelRegistry: ETS-backed registry for storing, retrieving,
  and versioning world models.

  Follows the MathematicsRegistry pattern: pure module with a public named ETS
  table. No GenServer — all operations are direct ETS calls.

  ## Storage
  - Primary key: `{model_id, version}` (tuple of string, integer)
  - Value: `%WorldModel{}` struct or map with atom keys
  - Metadata entries: `{:meta, model_id}` for latest version tracking
  - Fingerprint index: `{:fingerprint, fingerprint}` for reverse lookup
  """

  @registry_table :wm_model_registry

  @doc false
  def init_table do
    if :ets.info(@registry_table) == :undefined do
      :ets.new(@registry_table, [:set, :public, :named_table, read_concurrency: true])
    end
    :ok
  end

  @doc """
  Store a model in the registry. If no version is specified, auto-increments
  from the latest version. Returns the stored model map with updated version.
  """
  @spec store_model(map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def store_model(model, opts \\ []) do
    init_table()

    with {:ok, entry} <- build_entry(model, opts) do
      key = {entry.model_id, entry.version}
      :ets.insert(@registry_table, {key, entry})

      :ets.insert(@registry_table, {{:meta, entry.model_id}, %{
        model_id: entry.model_id,
        latest_version: entry.version,
        latest_fingerprint: entry.fingerprint,
        status: entry.status,
        name: entry.name,
        domain: entry.domain,
        updated_at: entry.created_at
      }})

      if entry.fingerprint do
        :ets.insert(@registry_table, {{:fingerprint, entry.fingerprint}, entry.model_id})
      end

      {:ok, entry}
    end
  end

  @doc """
  Retrieve a specific model version. Returns `{:ok, model}` or `{:error, :not_found}`.
  """
  @spec get_model(String.t(), non_neg_integer()) :: {:ok, map()} | {:error, :not_found}
  def get_model(model_id, version) do
    init_table()
    key = {model_id, version}

    case :ets.lookup(@registry_table, key) do
      [{^key, model}] -> {:ok, model}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Retrieve the latest version of a model.
  """
  @spec get_latest_model(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_latest_model(model_id) do
    init_table()

    case :ets.lookup(@registry_table, {:meta, model_id}) do
      [{{:meta, _}, meta}] ->
        get_model(model_id, meta.latest_version)
      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  List all model versions matching optional filters.

  Options:
    - `:domain` — filter by research domain atom
    - `:status` — filter by model status atom
    - `:name`   — filter by name substring (case-insensitive)
  """
  @spec list_models(keyword()) :: {:ok, [map()]}
  def list_models(opts \\ []) do
    init_table()

    domain = Keyword.get(opts, :domain)
    status = Keyword.get(opts, :status)
    name = Keyword.get(opts, :name)

    models =
      @registry_table
      |> :ets.tab2list()
      |> Enum.filter(fn {key, _} -> is_model_key?(key) end)
      |> Enum.map(fn {_, model} -> model end)
      |> Enum.filter(fn m -> domain == nil || m.domain == domain end)
      |> Enum.filter(fn m -> status == nil || m.status == status end)
      |> Enum.filter(fn m ->
        name == nil || String.downcase(m.name) =~ String.downcase(name)
      end)
      |> Enum.sort_by(fn m -> {m.model_id, m.version} end)

    {:ok, models}
  end

  @doc """
  List all versions of a specific model, sorted by version descending.
  """
  @spec list_versions(String.t()) :: {:ok, [map()]}
  def list_versions(model_id) do
    init_table()

    versions =
      @registry_table
      |> :ets.tab2list()
      |> Enum.filter(fn {key, _} -> is_model_key?(key) && elem(key, 0) == model_id end)
      |> Enum.map(fn {_, model} -> model end)
      |> Enum.sort_by(fn m -> m.version end, :desc)

    {:ok, versions}
  end

  @doc """
  Partially update a stored model. `updates` is a keyword list of fields to change.
  """
  @spec update_model(String.t(), non_neg_integer(), keyword()) :: {:ok, map()} | {:error, term()}
  def update_model(model_id, version, updates) do
    init_table()
    key = {model_id, version}

    with {:ok, entry} <- get_model(model_id, version) do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      updated = Enum.reduce(updates, entry, fn {k, v}, acc ->
        Map.put(acc, k, v)
      end)
      updated = Map.put(updated, :updated_at, now)

      :ets.insert(@registry_table, {key, updated})
      maybe_update_meta(updated)

      {:ok, updated}
    end
  end

  @doc """
  Transition a model's status with lifecycle validation.

  Valid transitions:
    - draft -> validated
    - validated -> operational
    - operational -> deprecated
    - deprecated -> draft (re-open)
    - any -> archived
  """
  @spec transition_status(String.t(), non_neg_integer(), atom()) :: {:ok, map()} | {:error, String.t()}
  def transition_status(model_id, version, new_status) do
    init_table()

    with {:ok, entry} <- get_model(model_id, version),
         :ok <- validate_transition(entry.status, new_status) do
      update_model(model_id, version, status: new_status)
    end
  end

  @doc """
  Soft-delete a model by transitioning it to :archived.
  """
  @spec delete_model(String.t(), non_neg_integer()) :: {:ok, map()} | {:error, term()}
  def delete_model(model_id, version) do
    transition_status(model_id, version, :archived)
  end

  @doc """
  Check if any version of a model exists.
  """
  @spec model_exists?(String.t()) :: boolean()
  def model_exists?(model_id) do
    init_table()
    :ets.lookup(@registry_table, {:meta, model_id}) != []
  end

  @doc """
  Get total count of stored model versions.
  """
  @spec count_models() :: non_neg_integer()
  def count_models do
    init_table()

    @registry_table
    |> :ets.tab2list()
    |> Enum.count(fn {key, _} -> is_model_key?(key) end)
  end

  @doc """
  Look up a model by its fingerprint hash. Returns the latest version matching.
  """
  @spec get_model_by_fingerprint(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_model_by_fingerprint(fingerprint) do
    init_table()

    case :ets.lookup(@registry_table, {:fingerprint, fingerprint}) do
      [{{:fingerprint, _}, model_id}] -> get_latest_model(model_id)
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Transfer a model to a new model_id (used for evolution forks).
  New model starts at version 1 with :draft status.
  """
  @spec transfer_model(String.t(), non_neg_integer(), keyword()) :: {:ok, map()} | {:error, term()}
  def transfer_model(model_id, version, opts \\ []) do
    init_table()
    new_id = Keyword.get(opts, :new_model_id, model_id <> "_fork")

    with {:ok, entry} <- get_model(model_id, version) do
      forked = Map.merge(entry, %{
        model_id: new_id,
        version: 1,
        status: :draft,
        fingerprint: nil,
        certificate: nil,
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        updated_at: nil
      })

      store_model(forked)
    end
  end

  @doc """
  Reset the registry table (used in tests).
  """
  @spec reset_table() :: :ok
  def reset_table do
    if :ets.info(@registry_table) != :undefined do
      :ets.delete(@registry_table)
    end
    init_table()
    :ok
  end

  defp is_model_key?({model_id, version}) when is_binary(model_id) and is_integer(version), do: true
  defp is_model_key?(_), do: false

  # -- private helpers --

  defp build_entry(model, opts) do
    forced = Keyword.get(opts, :force, false)
    model_id = model.model_id
    version = model.version

    cond do
      is_nil(model_id) ->
        {:error, "model_id is required"}

      version == nil and not forced ->
        next = next_version(model_id)
        {:ok, Map.put(model, :version, next)}

      version != nil and not forced ->
        case get_model(model_id, version) do
          {:ok, _} -> {:error, "model #{model_id} version #{version} already exists"}
          {:error, :not_found} -> {:ok, model}
        end

      forced ->
        {:ok, model}
    end
  end

  defp next_version(model_id) do
    case :ets.lookup(@registry_table, {:meta, model_id}) do
      [{{:meta, _}, meta}] -> meta.latest_version + 1
      [] -> 1
    end
  end

  defp maybe_update_meta(%{model_id: mid, version: ver, status: st, fingerprint: fp, name: nm, domain: dm}) do
    :ets.insert(@registry_table, {{:meta, mid}, %{
      model_id: mid,
      latest_version: ver,
      latest_fingerprint: fp,
      status: st,
      name: nm,
      domain: dm,
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }})

    if fp do
      :ets.insert(@registry_table, {{:fingerprint, fp}, mid})
    end
  end

  defp maybe_update_meta(_), do: :ok

  @valid_transitions %{
    draft: [:validated, :archived],
    validated: [:operational, :archived],
    operational: [:deprecated, :archived],
    deprecated: [:draft, :archived],
    archived: []
  }

  defp validate_transition(current, _new) when current not in [:draft, :validated, :operational, :deprecated, :archived] do
    {:error, "unknown current status: #{current}"}
  end

  defp validate_transition(_current, new) when new not in [:draft, :validated, :operational, :deprecated, :archived] do
    {:error, "unknown target status: #{new}"}
  end

  defp validate_transition(current, new) do
    allowed = Map.get(@valid_transitions, current, [])

    if new in allowed do
      :ok
    else
      {:error, "invalid transition from #{current} to #{new}"}
    end
  end
end
