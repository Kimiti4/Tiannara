defmodule Tiannara.REA.Epistemic.Vaccine do
  @derive {Jason.Encoder, only: [:pathogen_id, :signature_baseline, :efficacy, :epoch_created]}
  defstruct [:pathogen_id, :signature_baseline, :efficacy, :epoch_created]
end

defmodule Tiannara.REA.Epistemic.VaccineRegistry do
  use GenServer
  alias Tiannara.REA.Epistemic.Vaccine

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  @doc "Register a new cure (creating a vaccine)."
  def register_cure(pathogen_id, signature_baseline, epoch) do
    GenServer.call(__MODULE__, {:register_cure, pathogen_id, signature_baseline, epoch})
  end

  @doc "Calculate protective coefficient against a threat signature using Jaccard/similarity logic."
  def calculate_protection(pathogen_signature) do
    GenServer.call(__MODULE__, {:calculate_protection, pathogen_signature})
  end

  @doc "Decay vaccine efficacy over time according to Law P5 (Immune Drift)."
  def decay_efficacy(drift_constant \\ 0.02) do
    GenServer.call(__MODULE__, {:decay_efficacy, drift_constant})
  end

  @doc "Get all registered vaccines."
  def get_vaccines, do: GenServer.call(__MODULE__, :get_vaccines)

  @doc "Reset the vaccine registry."
  def reset, do: GenServer.call(__MODULE__, :reset)

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, %{vaccines: []}}
  end

  @impl true
  def handle_call({:register_cure, pathogen_id, signature, epoch}, _from, state) do
    # Check if vaccine already exists for this pathogen, overwrite or update it
    existing_filtered = Enum.reject(state.vaccines, &(&1.pathogen_id == pathogen_id))
    new_vaccine = %Vaccine{
      pathogen_id: pathogen_id,
      signature_baseline: signature,
      efficacy: 1.0,
      epoch_created: epoch
    }
    {:reply, :ok, %{state | vaccines: [new_vaccine | existing_filtered]}}
  end

  @impl true
  def handle_call({:calculate_protection, signature}, _from, state) do
    if Enum.empty?(state.vaccines) do
      {:reply, 0.0, state}
    else
      # Calculate best match protection coefficient
      max_protection =
        state.vaccines
        |> Enum.map(fn vac ->
          similarity = calculate_similarity(signature, vac.signature_baseline)
          similarity * vac.efficacy
        end)
        |> Enum.max(fn -> 0.0 end)

      {:reply, max_protection, state}
    end
  end

  @impl true
  def handle_call({:decay_efficacy, drift_constant}, _from, state) do
    decayed =
      Enum.map(state.vaccines, fn vac ->
        # Efficacy decay capped at 0.0
        %{vac | efficacy: max(0.0, vac.efficacy - drift_constant)}
      end)

    {:reply, :ok, %{state | vaccines: decayed}}
  end

  @impl true
  def handle_call(:get_vaccines, _from, state) do
    {:reply, state.vaccines, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{vaccines: []}}
  end

  # --- PRIVATE HELPERS ---

  defp calculate_similarity(sig1, sig2) do
    keys1 = Map.keys(sig1) |> MapSet.new()
    keys2 = Map.keys(sig2) |> MapSet.new()

    intersection = MapSet.intersection(keys1, keys2)
    union = MapSet.union(keys1, keys2)

    union_size = MapSet.size(union)

    if union_size == 0 do
      0.0
    else
      # Jaccard overlap of keys
      jaccard_keys = MapSet.size(intersection) / union_size

      # Value similarity over intersecting keys
      val_sims =
        intersection
        |> MapSet.to_list()
        |> Enum.map(fn k ->
          v1 = Map.get(sig1, k)
          v2 = Map.get(sig2, k)
          # Similarity is 1.0 - absolute delta
          1.0 - abs(v1 - v2)
        end)

      mean_val_sim =
        if Enum.empty?(val_sims) do
          1.0
        else
          Enum.sum(val_sims) / length(val_sims)
        end

      jaccard_keys * mean_val_sim
    end
  end
end
