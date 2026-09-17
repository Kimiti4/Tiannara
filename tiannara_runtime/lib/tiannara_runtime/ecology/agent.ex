defmodule Tiannara.Agent do
  @moduledoc """
  Represents a single cognitive entity within a Civilization.
  Agents are pure data structs (not GenServers) to allow thousands 
  per civilization without scheduler pressure.
  """
  @enforce_keys [:id, :caste]

  defstruct [
    :id,
    :caste,          # :prover, :falsifier, :explorer, :synthesizer, :historian

    :energy,         # Internal epistemic budget
    :focus_field,    # Which Millennium problem they are exploring

    :knowledge_state,
    :reward_score,

    :memory_trace,
    :mutation_rate,

    :loyalty_index,  # Loyalty to the dominant faction
    :novelty_bias,   # Preference for high-entropy regions

    :status          # :active, :idle, :exhausted
  ]

  @doc """
  Initializes a new agent of a specific caste.
  """
  def new(caste, focus_field) do
    %__MODULE__{
      id: :crypto.strong_rand_bytes(8) |> Base.encode16(),
      caste: caste,
      energy: 1.0,
      focus_field: focus_field,
      knowledge_state: [],
      reward_score: 0.0,
      memory_trace: [],
      mutation_rate: :rand.uniform() * 0.1,
      loyalty_index: 0.5 + (:rand.uniform() * 0.5),
      novelty_bias: if(caste == :explorer, do: 0.9, else: :rand.uniform() * 0.5),
      status: :active
    }
  end

  @doc """
  Evaluates the agent's action and computes the reward gradient and energy cost.
  Returns {updated_agent, reward, cost, action_result}
  """
  def act(%__MODULE__{caste: :prover} = agent) do
    # Provers stabilize structures
    cost = 0.05
    reward = 0.1 # R_p = C + S - D
    { %{agent | energy: agent.energy - cost, reward_score: agent.reward_score + reward}, reward, cost, :stabilize }
  end

  def act(%__MODULE__{caste: :falsifier} = agent) do
    # Falsifiers attack assumptions
    cost = 0.05
    reward = 0.15 # R_f = D_exposed + U_unstable
    { %{agent | energy: agent.energy - cost, reward_score: agent.reward_score + reward}, reward, cost, :attack }
  end

  def act(%__MODULE__{caste: :explorer} = agent) do
    # Explorers search entropy regions
    cost = 0.02
    reward = 0.2 # R_e = N_novelty - C_stagnation
    { %{agent | energy: agent.energy - cost, reward_score: agent.reward_score + reward}, reward, cost, :explore }
  end

  def act(%__MODULE__{caste: :synthesizer} = agent) do
    # Synthesizers merge abstractions
    cost = 0.10
    reward = 0.3 # R_s = X_crossfield + A_abstraction
    { %{agent | energy: agent.energy - cost, reward_score: agent.reward_score + reward}, reward, cost, :synthesize }
  end

  def act(%__MODULE__{caste: :historian} = agent) do
    # Historians preserve civilization memory
    cost = 0.03
    reward = 0.05
    { %{agent | energy: agent.energy - cost, reward_score: agent.reward_score + reward}, reward, cost, :preserve }
  end
end
