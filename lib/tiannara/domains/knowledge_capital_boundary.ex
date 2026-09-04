defmodule Tiannara.Domains.KnowledgeCapitalBoundary do
  @moduledoc """
  Boundary module for knowledge capital queries.

  Knowledge capital is NOT a domain identity concern. It belongs to
  `TiannaraOS.KnowledgeCapital` (pure-function calculator) and is computed
  from research program state at runtime.

  This boundary exists to provide a stable migration target for legacy
  `get_knowledge_capital/1` callers on the defunct `DomainRegistry` and
  `Tiannara.Domains.Registry` modules, which never implemented this
  functionally (all calls were already failing with noproc/undef).

  ## Contract

  - `get/1` → always returns `nil` (knowledge capital unavailable without active programs)
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
