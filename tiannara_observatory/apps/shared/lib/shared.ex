defmodule Shared do
  @moduledoc "Shared types and constants for the Constitutional Observatory."
  defdelegate constitution_version, to: Shared.Constants
  defdelegate api_version, to: Shared.Constants
  defdelegate schema_version, to: Shared.Constants
end
