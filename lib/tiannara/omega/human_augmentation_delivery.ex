defmodule Tiannara.Omega.HumanAugmentationDelivery.Explanation do
  @moduledoc """
  Delegate namespace mirroring `Tiannara.Omega.HumanDelivery.Explanation`
  under the HumanAugmentationDelivery tree. The narrative contract is shared:
  every explanation states confidence AND uncertainty and ends by declaring
  that deployment requires human authorization.
  """

  defdelegate build(package), to: Tiannara.Omega.HumanDelivery.Explanation
  defdelegate render_narrative(explanation), to: Tiannara.Omega.HumanDelivery.Explanation
end

defmodule Tiannara.Omega.HumanAugmentationDelivery.Authorization do
  @moduledoc """
  Delegate namespace mirroring `Tiannara.Omega.HumanDelivery.Authorization`
  under the HumanAugmentationDelivery tree. The authority boundary is shared:
  a grant can ONLY be minted by an explicit human decision carrying a
  `human_id`; there is no autonomous path to a valid grant.
  """

  defdelegate prepare(explanation), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate request(auth), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate human_grant(auth, human_id), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate human_grant(auth, human_id, opts), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate human_deny(auth, reason), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate valid_for?(auth, explanation_id), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate valid_for_effect?(auth, descriptor), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate expired?(grant), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate expired?(grant, now), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate expire(auth), to: Tiannara.Omega.HumanDelivery.Authorization
  defdelegate expire(auth, now), to: Tiannara.Omega.HumanDelivery.Authorization
end

defmodule Tiannara.Omega.HumanAugmentationDelivery do
  @moduledoc """
  The human-augmentation delivery layer (augmentation-clause entry point).

  Takes a held decision from the governance gate, produces a transparent
  explanation, renders the narrative, and requests human authorization.

  AUTHORITY BOUNDARY (constitutional): this layer PREPARES explanations and
  REQUESTS authorization. It does NOT decide, and it does NOT deploy. The
  decision belongs to the human; deployment requires the resulting
  AuthorizationGrant.

  Constitutional basis: augmentation clause (final constitutional clause),
  Explainability, "Uncertainty should never be hidden", "Maintain audit
  trails".
  """
  use GenServer

  require Logger

  alias Tiannara.Omega.HumanAugmentationDelivery.{Explanation, Authorization}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  # --- pure core ----------------------------------------------------------

  @doc "Produce a transparent explanation from a decision package."
  def explain(package), do: Explanation.build(package)

  @doc "Render the narrative arc for a human."
  def render(explanation), do: Explanation.render_narrative(explanation)

  @doc """
  Prepare and request authorization for an explanation. Returns a pending
  authorization awaiting a human decision.
  """
  def request_authorization(explanation) do
    with {:ok, auth} <- Authorization.prepare(explanation),
         {:ok, pending} <- Authorization.request(auth) do
      Logger.info("Authorization requested for ID: #{auth.authorization_id}")
      {:ok, pending}
    end
  end

  # --- GenServer (pending-authorization state) ---------------------------

  @impl true
  def init(_opts) do
    Logger.info("Initializing HumanAugmentationDelivery with empty authorization state")
    Process.send_after(self(), :cleanup_expired, 60 * 60 * 1000)
    {:ok, %{pending: %{}, granted: %{}, denied: %{}}}
  end

  @impl true
  def handle_call({:deliver, package}, _from, state) do
    Logger.info("Delivering decision package for human authorization")

    explanation = explain(package)
    {:ok, auth} = request_authorization(explanation)

    state = %{state | pending: Map.put(state.pending, auth.authorization_id, {explanation, auth})}

    response =
      {:ok,
       %{
         explanation: explanation,
         authorization: auth,
         narrative: render(explanation),
         status: "Pending human authorization"
       }}

    Logger.info("Decision package delivered successfully with authorization ID: #{auth.authorization_id}")
    {:reply, response, state}
  end

  @impl true
  def handle_call({:authorize, authorization_id, human_id}, _from, state) do
    case Map.get(state.pending, authorization_id) do
      nil ->
        {:reply, {:error, :unknown_authorization}, state}

      {explanation, auth} ->
        case Authorization.human_grant(auth, human_id) do
          {:ok, granted} ->
            state = %{
              state
              | pending: Map.delete(state.pending, authorization_id),
                granted: Map.put(state.granted, authorization_id, {explanation, granted})
            }

            {:reply, {:ok, granted}, state}

          {:error, _} = e ->
            {:reply, e, state}
        end
    end
  end

  @impl true
  def handle_call({:deny, authorization_id, reason}, _from, state) do
    case Map.get(state.pending, authorization_id) do
      nil ->
        {:reply, {:error, :unknown_authorization}, state}

      {explanation, auth} ->
        case Authorization.human_deny(auth, reason) do
          {:ok, denied} ->
            state = %{
              state
              | pending: Map.delete(state.pending, authorization_id),
                denied: Map.put(state.denied, authorization_id, {explanation, denied})
            }

            {:reply, {:ok, denied}, state}

          {:error, _} = e ->
            {:reply, e, state}
        end
    end
  end

  @impl true
  def handle_call(:pending, _from, state) do
    pending_ids = Map.keys(state.pending)
    Logger.debug("Retrieved #{length(pending_ids)} pending authorizations")
    {:reply, pending_ids, state}
  end

  @impl true
  def handle_info(:cleanup_expired, state) do
    Logger.info("Cleaning up expired authorizations")

    twenty_four_hours_ago = DateTime.utc_now() |> DateTime.add(-86400)

    cleaned_pending =
      Enum.filter(state.pending, fn {_id, {_explanation, auth}} ->
        DateTime.compare(auth.requested_at, twenty_four_hours_ago) == :gt
      end)
      |> Enum.into(%{})

    one_week_ago = DateTime.utc_now() |> DateTime.add(-604800)

    cleaned_granted =
      Enum.filter(state.granted, fn {_id, {_explanation, granted}} ->
        DateTime.compare(granted.granted_at, one_week_ago) == :gt
      end)
      |> Enum.into(%{})

    cleaned_denied =
      Enum.filter(state.denied, fn {_id, {_explanation, denied}} ->
        DateTime.compare(denied.denied_at, one_week_ago) == :gt
      end)
      |> Enum.into(%{})

    new_state = %{
      state
      | pending: cleaned_pending,
        granted: cleaned_granted,
        denied: cleaned_denied
    }

    Process.send_after(self(), :cleanup_expired, 24 * 60 * 60 * 1000)
    {:noreply, new_state}
  end

  # --- public API ---------------------------------------------------------

  @doc """
  Deliver a decision package to the human for review and authorization.

  Returns a map containing:
  - explanation: The transparent explanation of the decision
  - authorization: The pending authorization object
  - narrative: The rendered narrative arc for human understanding
  """
  def deliver(server \\ __MODULE__, package) do
    Logger.debug("Initiating delivery of decision package")
    GenServer.call(server, {:deliver, package})
  end

  @doc """
  Process a human authorization grant for a specific authorization request.
  """
  def authorize(server \\ __MODULE__, authorization_id, human_id) do
    Logger.info("Processing authorization grant for ID: #{authorization_id}")
    GenServer.call(server, {:authorize, authorization_id, human_id})
  end

  @doc """
  Process a human authorization denial for a specific authorization request.
  """
  def deny(server \\ __MODULE__, authorization_id, reason) do
    Logger.info("Processing authorization denial for ID: #{authorization_id}")
    GenServer.call(server, {:deny, authorization_id, reason})
  end

  @doc """
  Get a list of all pending authorizations (IDs waiting for human decision).
  """
  def pending(server \\ __MODULE__) do
    Logger.debug("Retrieving list of pending authorizations")
    GenServer.call(server, :pending)
  end
end