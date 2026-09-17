defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Behaviours.CampaignBehaviour do
  @moduledoc """
  Defines the contract for executing and managing research campaigns.
  Implementations handle campaign execution, status reporting, and cancellation.
  """

  @callback execute_campaign(
              TiannaraRuntime.WorldModel.AutonomousResearch.ResearchCampaign.t(),
              keyword()
            ) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ResearchCampaign.t()} | {:error, term()}

  @callback get_campaign_status(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchCampaign.t()) ::
              {:ok, atom()} | {:error, term()}

  @callback cancel_campaign(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchCampaign.t()) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ResearchCampaign.t()} | {:error, term()}
end
