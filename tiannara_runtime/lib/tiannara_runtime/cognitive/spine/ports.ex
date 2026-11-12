defmodule TiannaraRuntime.Cognitive.Spine.Authority do
  @moduledoc """
  Authority port for the Cognitive Execution Spine.

  The Spine may *sequence* cognitive work, but it may never *authorise* a
  privileged action on its own. The authority to act is injected through
  this port; without an adapter that grants authorisation, the Spine's
  terminal gate refuses and the investigation completes without a mandate.

  Implementations are supplied by the governing stack (the application that
  owns the Council and the constitutional authority). The default adapter
  refuses, so a Spine that has been started but not yet wired to an authority
  is safe by construction.
  """

  @type request :: map()
  @type authorization :: map()
  @type reason :: term()

  @callback authorize(request()) :: {:ok, authorization()} | {:error, reason()}

  @doc """
  The default adapter: refuses every authorisation request.

  It exists so that an unwired Spine is explicitly unavailable rather than
  accidentally permissive.
  """
  defmodule Refusing do
    @moduledoc """
    Default authority adapter. Refuses every request with
    `{:error, :authority_unavailable}`.
    """
    @behaviour TiannaraRuntime.Cognitive.Spine.Authority

    @impl true
    def authorize(_request), do: {:error, :authority_unavailable}
  end
end

defmodule TiannaraRuntime.Cognitive.Spine.Knowledge do
  @moduledoc """
  Knowledge port for the Cognitive Execution Spine.

  The Spine produces validated knowledge; the knowledge port decides whether
  and where it is *retained*, and whether a hypothesis is promoted to
  established knowledge. The default adapter refuses, so nothing is written
  until a store is wired in — the spine never silently discards a validated
  conclusion either, it reports it as blocked.
  """

  @type conclusion :: map()
  @type evidence :: map()
  @type reason :: term()

  @callback promote(conclusion(), evidence()) :: {:ok, map()} | {:error, reason()}
  @callback record_outcome(conclusion(), evidence()) :: {:ok, map()} | {:error, reason()}

  @doc """
  The default adapter: refuses every persistence request.

  It exists so that an unwired Spine reports `{:error, :knowledge_store_unavailable}`
  rather than pretending a conclusion was retained.
  """
  defmodule Refusing do
    @moduledoc """
    Default knowledge adapter. Refuses every request with
    `{:error, :knowledge_store_unavailable}`.
    """
    @behaviour TiannaraRuntime.Cognitive.Spine.Knowledge

    @impl true
    def promote(_conclusion, _evidence), do: {:error, :knowledge_store_unavailable}

    @impl true
    def record_outcome(_conclusion, _evidence), do: {:error, :knowledge_store_unavailable}
  end
end
