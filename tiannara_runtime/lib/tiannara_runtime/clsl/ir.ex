defmodule Tiannara.CLSL.IR do
  @moduledoc """
  Causal Language Standardization Layer: IR.
  
  The LLVM for existence grammars. Ensures causal interoperability
  without silently destroying exotic physics.
  """
  
  defstruct [
    :id,
    :time_model,
    :identity_model,
    :entropy_model,
    :physics_bindings,
    :observer_model,
    :recursion_model,
    :topology_model,
    :causal_resolution_model,
    :translation_loss
  ]
end

defmodule Tiannara.CLSL.IRTranslationLoss do
  @moduledoc """
  Tracks what could NOT be translated cleanly into the IR.
  Prevents the CLSL from silently acting as an assimilation layer.
  """
  
  defstruct [
    semantic_loss: 0.0,
    causal_loss: 0.0,
    observer_loss: 0.0,
    topology_loss: 0.0,
    untranslated_primitives: []
  ]
end
