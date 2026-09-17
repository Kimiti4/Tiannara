defmodule TiannaraRuntime.Civilization do
  @moduledoc "Phase 19 — Constitutional Civilizational Intelligence"
  @version "19.999"
  @cri_level "CRI-6"

  def version, do: @version
  def cri_level, do: @cri_level
  def description, do: "Constitutional Civilizational Intelligence Runtime"
  def subsystems, do: [:ontology, :registry, :runtime, :economy, :portfolio, :coordination, :planning, :scenarios]
end
