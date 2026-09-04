defmodule Tiannara.Agency.HumanInterface do
  @moduledoc """
  Human Interface for agency notifications and approval requests.
  In production, connects to Observatory UI, messaging, email, etc.
  """
  require Logger

  def deliver(notification) do
    Logger.info("[HumanInterface] Notification: [#{notification.severity}] #{notification.summary}")
    :ok
  end

  def request_approval(decision_request) do
    Logger.info("[HumanInterface] Approval requested for experiment #{decision_request.experiment_id}")
    :ok
  end
end
