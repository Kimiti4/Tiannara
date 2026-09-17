defmodule Tiannara.Sentinel.Contracts.Severity do
  @moduledoc """
  Defines the shared risk vocabulary across the Sentinel framework.
  """
  @type t :: :info | :warning | :elevated | :critical | :terminal
end
