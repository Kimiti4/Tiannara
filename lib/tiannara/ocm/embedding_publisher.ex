defmodule Tiannara.OCM.EmbeddingPublisher do
  @moduledoc """
  Node interface for civilizations to publish their semantic vectors.
  """
  
  def publish(civilization, concept, definition) do
    Tiannara.OCM.ConsensusMesh.publish_and_evaluate(civilization, concept, definition)
  end
end
