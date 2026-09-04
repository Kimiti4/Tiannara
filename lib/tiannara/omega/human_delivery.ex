defmodule Tiannara.Omega.HumanDelivery do
  @moduledoc """
  The human-augmentation delivery layer. Takes a held decision from the
  governance gate, produces a transparent explanation, renders the narrative,
  and requests human authorization.

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

  alias Tiannara.Omega.HumanDelivery.{Explanation, Authorization}

  @callback explain(package :: map()) :: Explanation.t()
  @callback request_authorization(explanation :: Explanation.t()) ::
              {:ok, Authorization.t()} | {:error, term()}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  # --- pure core ----------------------------------------------------------

  @doc "Produce a transparent explanation from a decision package."
  def explain(package), do: Explanation.build(package)

  @doc "Render the narrative arc for a human."
  def render(%Explanation{} = explanation), do: Explanation.render_narrative(explanation)

  @doc """
  Prepare and request authorization for an explanation. Returns a pending
  authorization awaiting a human decision.

  This function follows the authorization workflow:
  1. Prepare the authorization request with the explanation
  2. Submit the request to the authorization system
  3. Return the pending authorization object
  """
  def request_authorization(%Explanation{} = explanation) do
    with {:ok, auth} <- Authorization.prepare(explanation),
         {:ok, pending} <- Authorization.request(auth) do
      Logger.info("Authorization requested for ID: #{auth.authorization_id}")
      {:ok, pending}
    end
  end

  # --- GenServer (pending-authorization state) ---------------------------

  @impl true
  def init(_opts) do
    Logger.info("Initializing HumanDelivery with empty authorization state")
    # Set up a periodic check to clean up expired authorizations every hour
    Process.send_after(self(), :cleanup_expired, 60 * 60 * 1000)
    {:ok, %{pending: %{}, granted: %{}, denied: %{}}}
  end

  @impl true
  def handle_call({:deliver, package}, _from, state) do
    Logger.info("Delivering decision package for human authorization")
    
    explanation = explain(package)
    {:ok, auth} = request_authorization(explanation)

    state = %{state | pending: Map.put(state.pending, auth.authorization_id, {explanation, auth})}
    
    response = {:ok, %{
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
    
    # Clean up pending authorizations older than 24 hours
    twenty_four_hours_ago = DateTime.utc_now() |> DateTime.add(-86400)
    cleaned_pending = Enum.filter(state.pending, fn {_id, {_explanation, auth}} ->
      DateTime.compare(auth.requested_at, twenty_four_hours_ago) == :gt
    end) |> Enum.into(%{})
    
    # Clean up granted authorizations older than 7 days
    one_week_ago = DateTime.utc_now() |> DateTime.add(-604800)
    cleaned_granted = Enum.filter(state.granted, fn {_id, {_explanation, granted}} ->
      DateTime.compare(granted.granted_at, one_week_ago) == :gt
    end) |> Enum.into(%{})
    
    # Clean up denied authorizations older than 7 days
    cleaned_denied = Enum.filter(state.denied, fn {_id, {_explanation, denied}} ->
      DateTime.compare(denied.denied_at, one_week_ago) == :gt
    end) |> Enum.into(%{})
    
    new_state = %{
      state 
      | pending: cleaned_pending,
        granted: cleaned_granted,
        denied: cleaned_denied
    }
    
    # Schedule next cleanup in 24 hours
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
  
  Returns:
  - {:ok, granted_authorization} if successful
  - {:error, :unknown_authorization} if the authorization ID doesn't exist
  - {:error, reason} if there was a problem processing the authorization
  """
  def authorize(server \\ __MODULE__, authorization_id, human_id) do
    Logger.info("Processing authorization grant for ID: #{authorization_id}")
    GenServer.call(server, {:authorize, authorization_id, human_id})
  end

  @doc """
  Process a human authorization denial for a specific authorization request.
  
  Returns:
  - {:ok, denied_authorization} if successful
  - {:error, :unknown_authorization} if the authorization ID doesn't exist
  - {:error, reason} if there was a problem processing the denial
  """
  def deny(server \\ __MODULE__, authorization_id, reason) do
    Logger.info("Processing authorization denial for ID: #{authorization_id}")
    GenServer.call(server, {:deny, authorization_id, reason})
  end

  @doc """
  Get a list of all pending authorizations.
  
  Returns a list of authorization IDs that are currently waiting for human decision.
  """
  def pending(server \\ __MODULE__) do
    Logger.debug("Retrieving list of pending authorizations")
    GenServer.call(server, :pending)
  end
end