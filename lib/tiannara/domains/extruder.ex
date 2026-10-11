defmodule Tiannara.Domains.Extruder do
  @moduledoc """
  Domain dispatcher for blueprint extraction.

  Only explicitly implemented domain extractors are dispatched. Unsupported
  domains return a failure record instead of silently using the engineering
  extractor and mislabelling the resulting artifact.
  """

  @type blueprint :: %{
          required(:domain) => atom(),
          required(:status) => :success | :failed,
          optional(:schematics) => String.t(),
          optional(:confidence) => float(),
          optional(:reason) => term()
        }

  @callback extract_blueprint(
              intent :: atom(),
              world_context :: map(),
              discoveries :: list()
            ) :: blueprint()

  @doc """
  Route to an implemented domain extractor. World context and discoveries are
  explicit placeholders until their canonical providers are wired; callers
  must not infer that those inputs contain live world state.
  """
  def extract_blueprint(domain, primary_intent) do
    case domain_module(domain) do
      nil ->
        %{domain: domain, status: :failed, reason: {:unsupported_domain, domain}}

      module ->
        world_context = %{source: :default_placeholder, bias: 1.0}
        discoveries = []
        module.extract_blueprint(primary_intent, world_context, discoveries)
    end
  end

  defp domain_module(:engineering), do: Tiannara.Domains.Extruder.Engineering
  defp domain_module(:energy), do: Tiannara.Domains.Extruder.Energy
  defp domain_module(:computation), do: Tiannara.Domains.Extruder.Computation
  defp domain_module(_), do: nil
end
