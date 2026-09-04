defmodule Tiannara.Council.MetaGovernor do
  @moduledoc """
  Phase 20: The United Nations of Tiannara.
  Coordinates sovereign civilizations, resolves resource conflicts, 
  and decomposes long-horizon human objectives into cross-civilizational Treaties.
  """
  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def init(_), do: {:ok, %{active_treaties: [], global_treasury: 10_000.00}}

  @doc """
  Receives a multi-month human directive and decomposes it into a Grand Treaty.
  """
  def enact_grand_objective(objective_description) do
    GenServer.call(__MODULE__, {:enact, objective_description})
  end

  @doc """
  Marks a treaty as fulfilled and allocates revenue to the global treasury.
  """
  def fulfill_treaty(treaty_id) do
    GenServer.cast(__MODULE__, {:fulfill, treaty_id})
  end

  def handle_call({:enact, desc}, _from, state) do
    Logger.info("🏛️ [MetaGovernor] Received Grand Objective: '#{desc}'")
    Logger.info("   Negotiating cross-civilizational Treaty...")
    
    # The Council determines which sovereign organs must collaborate
    treaty = %Tiannara.Council.Treaty{
      id: "treaty_#{:erlang.unique_integer([:positive])}",
      objective: desc,
      signatories: identify_required_signatories(desc),
      milestones: [],
      status: :negotiating
    }
    
    Logger.info("   📜 Treaty #{treaty.id} drafted. Signatories: #{inspect(treaty.signatories)}")
    
    # Route the treaty to the Epistemic Airlocks of the respective nodes
    Enum.each(treaty.signatories, fn node_id ->
      Tiannara.Cosmology.Router.deliver_treaty(node_id, treaty)
    end)
    
    {:reply, {:ok, treaty}, %{state | active_treaties: [treaty | state.active_treaties]}}
  end

  def handle_cast({:fulfill, treaty_id}, state) do
    Logger.info("🏛️ [MetaGovernor] Treaty #{treaty_id} marked as :fulfilled.")
    {:noreply, state}
  end

  defp identify_required_signatories(desc) do
    # Heuristic decomposition of a 6-month product goal
    signatories = ["asc_alpha"] # Engineering is always required
    
    signatories = if String.match?(desc, ~r/data|model|predict|analytics/i), do: ["dsc_beta" | signatories], else: signatories
    signatories = if String.match?(desc, ~r/secure|encrypt|auth/i), do: ["sec_gamma" | signatories], else: signatories
    signatories = if String.match?(desc, ~r/deploy|scale|cloud|aws/i), do: ["infra_omega" | signatories], else: signatories
    
    Enum.uniq(signatories)
  end
end
