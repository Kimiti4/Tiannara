defmodule ObservationBus.CIL.PatternRegistry do
  @moduledoc """
  ETS-backed registry for constitutional patterns discovered by the PatternEngine.

  Each stored pattern has:
    * `:id` — unique UUID
    * `:type` — pattern category (e.g. `:discovery_burst`, `:knowledge_stagnation`)
    * `:domain` — the constitutional domain the pattern was observed in
    * `:signature` — a hash-based fingerprint of the pattern
    * `:first_seen` — `DateTime` of first occurrence
    * `:last_seen` — `DateTime` of most recent occurrence
    * `:occurrence_count` — how many times this pattern has matched
    * `:confidence` — float 0.0–1.0
    * `:metadata` — arbitrary map of additional data
  """
  use GenServer

  @table_name :cil_pattern_registry

  defstruct [:id, :type, :domain, :signature, :first_seen, :last_seen,
             :occurrence_count, :confidence, :metadata]

  @type t :: %__MODULE__{
    id: String.t(),
    type: atom(),
    domain: String.t(),
    signature: String.t(),
    first_seen: DateTime.t(),
    last_seen: DateTime.t(),
    occurrence_count: non_neg_integer(),
    confidence: float(),
    metadata: map()
  }

  @pattern_types [
    :discovery_burst, :knowledge_stagnation, :experiment_bottleneck,
    :engineering_acceleration, :certification_regression, :resource_starvation
  ]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true,
                                   read_concurrency: true])
    {:ok, %{table: table, total_patterns: 0}}
  end

  @doc "Register a new pattern or update an existing one."
  @spec register_pattern(atom(), String.t(), String.t(), map()) :: {:ok, String.t()}
  def register_pattern(type, domain, signature, metadata \\ %{})
      when type in @pattern_types do
    GenServer.call(__MODULE__, {:register_pattern, type, domain, signature, metadata}, :infinity)
  end

  @doc "List all patterns, optionally filtered by type and/or domain."
  @spec list_patterns(keyword()) :: [t()]
  def list_patterns(filters \\ []) do
    type = Keyword.get(filters, :type)
    domain = Keyword.get(filters, :domain)

    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_key, p} -> p end)
    |> Enum.filter(fn p ->
      (is_nil(type) or p.type == type) and
      (is_nil(domain) or p.domain == domain)
    end)
    |> Enum.sort_by(& &1.last_seen, {:desc, DateTime})
  end

  @doc "Get a single pattern by ID."
  @spec get_pattern(String.t()) :: t() | nil
  def get_pattern(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, pattern}] -> pattern
      [] -> nil
    end
  end

  @doc "Get pattern count."
  @spec count() :: non_neg_integer()
  def count do
    :ets.info(@table_name, :size)
  end

  @doc "Get all distinct pattern types currently registered."
  @spec pattern_types_in_use() :: [atom()]
  def pattern_types_in_use do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_k, p} -> p.type end)
    |> Enum.uniq()
  end

  @impl true
  def handle_call({:register_pattern, type, domain, signature, metadata}, _from, state) do
    now = DateTime.utc_now()

    case lookup_by_signature(type, domain, signature) do
      nil ->
        id = uuid_v4()
        pattern = %__MODULE__{
          id: id,
          type: type,
          domain: domain,
          signature: signature,
          first_seen: now,
          last_seen: now,
          occurrence_count: 1,
          confidence: 0.5,
          metadata: metadata
        }
        :ets.insert(@table_name, {id, pattern})
        {:reply, {:ok, id}, %{state | total_patterns: state.total_patterns + 1}}

      existing ->
        updated = %{existing |
          last_seen: now,
          occurrence_count: existing.occurrence_count + 1,
          confidence: min(1.0, existing.confidence + 0.05)
        }
        :ets.insert(@table_name, {existing.id, updated})
        {:reply, {:ok, existing.id}, state}
    end
  end

  defp lookup_by_signature(type, domain, signature) do
    @table_name
    |> :ets.tab2list()
    |> Enum.find_value(fn {_id, p} ->
      if p.type == type and p.domain == domain and p.signature == signature, do: p
    end)
  end

  defp uuid_v4 do
    <<a::64, b::64>> = :crypto.strong_rand_bytes(16)
    <<u1::48, _::4, u2::12, _::2, u3::62>> = <<a::64, b::64>>
    <<u1::48, 4::4, u2::12, 2::2, u3::62>>
    |> Base.encode16(case: :lower)
    |> then(fn s ->
      "#{String.slice(s, 0, 8)}-#{String.slice(s, 8, 4)}-#{String.slice(s, 12, 4)}-#{String.slice(s, 16, 4)}-#{String.slice(s, 20, 12)}"
    end)
  end
end
