defmodule Tiannara.Council.PrinciplePlugin do
  @moduledoc """
  Behaviour for constitutional principle plugins.

  Each constitutional principle is implemented as a separate module
  implementing this behaviour, allowing independent versioning,
  testing, and evolution of principles without modifying the core
  RuleEngine.

  Implementations:

      defmodule Tiannara.Council.Principles.Transparency do
        use Tiannara.Council.PrinciplePlugin,
          name: :transparency,
          version: "2.1.0",
          weight: 0.10

        @impl true
        def score(decision_type, payload) do
          # custom scoring logic
        end
      end
  """

  @type principle_name :: atom()
  @type version :: String.t()
  @type weight :: float()
  @type score :: float()
  @type evidence :: [String.t()]

  @callback name() :: principle_name()
  @callback version() :: version()
  @callback weight() :: weight()
  @callback description() :: String.t()
  @callback score(atom(), map()) :: score()

  @doc "Returns evidence strings supporting the score."
  @callback evidence(atom(), map()) :: evidence()

  @doc "Returns whether this principle considers the decision a violation."
  @callback violated?(atom(), map(), score()) :: boolean()

  @optional_callbacks evidence: 2, violated?: 3

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Tiannara.Council.PrinciplePlugin

      @name Keyword.fetch!(opts, :name)
      @version Keyword.get(opts, :version, "1.0.0")
      @weight Keyword.fetch!(opts, :weight)

      @impl true
      def name, do: @name

      @impl true
      def version, do: @version

      @impl true
      def weight, do: @weight

      @impl true
      def description, do: "No description provided for #{@name}"

      @impl true
      def evidence(_decision_type, _payload), do: ["No evidence collected for #{@name}"]

      @impl true
      def violated?(_decision_type, _payload, score), do: score < 0.5

      defoverridable description: 0, evidence: 2, violated?: 3
    end
  end
end
