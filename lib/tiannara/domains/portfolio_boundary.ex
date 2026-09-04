defmodule Tiannara.Domains.PortfolioBoundary do
  @moduledoc """
  Boundary module for domain portfolio vector queries.

  Portfolio vectors are NOT a domain identity concern. They are computed
  from research program state, transfer matrix, and discovery yields.

  This boundary exists to provide a stable migration target for legacy
  `get_portfolio_vector/1` callers on the defunct `DomainRegistry` and
  `Tiannara.Domains.Registry` modules, which never implemented this
  functionally (all calls were already failing with noproc/undef).

  ## Contract

  - `get/1` → always returns `nil` (portfolio vector unavailable without active programs)
  - `available?/0` → `false`
  - `status/0` → `:unavailable`

  Once `TiannaraOS.ResearchDirector` and program infrastructure are
  operational, this boundary will delegate to the actual calculator.
  """

  @spec get(atom()) :: nil
  def get(_domain_id), do: nil

  @spec available?() :: false
  def available?, do: false

  @spec status() :: :unavailable
  def status, do: :unavailable
end
