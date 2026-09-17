defmodule TiannaraRuntime.Legacy.Tiannara.OLEF.ComputeBackend do
  @moduledoc """
  Behaviour for OLEF field tensor compute engines.
  Supports transparent switching between CPU, Rayon, and future CUDA architectures.
  """
  
  @callback diffuse(map(), map(), float(), integer()) :: map()
end
