defmodule Tiannara.Domains.Extruder.Energy do
  @moduledoc "Extrudes Energy blueprints."
  @behaviour Tiannara.Domains.Extruder

  @impl true
  def extract_blueprint(intent, _world_context, _discoveries) do
    %{
      domain: :energy,
      status: :success,
      schematics: "// Energy capacitance matrix for #{intent}\nmodule power_grid (input wire clk, output wire power_out);\n  assign power_out = 1'b1;\nendmodule",
      confidence: 0.92
    }
  end
end
