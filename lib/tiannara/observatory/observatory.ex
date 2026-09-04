defmodule Tiannara.Observatory do
  @moduledoc """
  Observatory root module — serves as the communication bridge between
  the Sentinel Activation Layer and the Observatory UI/interface.

  Provides push-based interfaces for Sentinel-initiated dialogues,
  approval proposals, and cognitive investigation reports.
  """
  require Logger

  @doc """
  Pushes a dialogue message from Sentinel to the Observatory interface.
  """
  def push_dialogue(msg) do
    Logger.info("[Observatory] Sentinel Dialogue: #{msg.category}/#{msg.severity}")
    Logger.debug("[Observatory] Dialogue detail: #{msg.message}")
    :ok
  end

  @doc """
  Pushes a proposal (action requiring approval) from Sentinel.
  """
  def push_proposal(proposal) do
    Logger.info("[Observatory] Sentinel Proposal: #{proposal.action}")
    Logger.debug("[Observatory] Proposal risk: #{proposal.risk_score}, benefit: #{proposal.expected_benefit}")
    :ok
  end

  @doc """
  Pushes a full cognitive investigation report from Sentinel's Cognition layer.
  """
  def push_investigation(report) do
    Logger.info("[Observatory] Sentinel Investigation Report")
    Logger.debug("[Observatory] Report:\n#{report}")
    :ok
  end
end
