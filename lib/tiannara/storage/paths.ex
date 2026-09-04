defmodule Tiannara.Storage.Paths do
  @moduledoc """
  Context-resolved storage paths.

  Every persistent artifact that must not cross-contaminate contexts resolves
  through `path/2`. The active context comes from the `:storage_context`
  application env (default `"production"`); `config/test.exs` pins `"test"`
  and the soak server boots with `STORAGE_CONTEXT=soak`.

  Contexts: `:production`, `:test`, `:soak`, `:simulation`, `:replay`,
  `:benchmarks`, `:harness`.

  Paths are resolved at RUNTIME (never as module attributes) so a server booted
  under one context can never read or write artifacts produced by another.
  """

  @contexts [:production, :test, :soak, :simulation, :replay, :benchmarks, :harness]
  @default_base "data"

  @doc "All valid storage contexts."
  def contexts, do: @contexts

  @doc "The active storage context (atom)."
  def context do
    Application.get_env(:tiannara, :storage_context, "production")
    |> to_string()
    |> String.trim()
    |> String.to_atom()
  end

  @doc """
  Resolves `artifact` under the ACTIVE context, e.g. `path("checkpoints/latest.json")`.
  """
  def path(artifact), do: path(context(), artifact)

  @doc "Resolves `artifact` under an explicit context."
  def path(context, artifact) do
    if context in @contexts do
      Path.join([base(), to_string(context), artifact])
    else
      raise ArgumentError,
            "unknown storage context #{inspect(context)}; valid: #{inspect(@contexts)}"
    end
  end

  @doc "The base directory for all storage contexts."
  def base, do: Application.get_env(:tiannara, :storage_base, @default_base)

  @doc """
  Resolves a DETS file path under the ACTIVE context, e.g.
  `dets("cel_event_store")` → `<env_base>/dets/soak/cel_event_store.dets`.

  DETS stores are unbounded unless pruned, so they MUST be context-resolved
  (a soak run must never share a store file with a production/test run) and
  MUST be registered with `Storage.DetsLifecycle` for size-bound rotation and
  retention pruning.

  When `:dets_base_path` is configured (test/dev/prod envs), it acts as the
  per-ENV base (kept for test isolation: `test.exs` pins a unique directory
  that `test_helper.exs` wipes) and the CONTEXT is layered under it as
  `<base>/dets/<context>/<name>.dets`. Without it, the storage base +
  context scheme (`data/<context>/dets/...`) applies.
  """
  def dets(name) do
    safe_name =
      name
      |> to_string()
      |> String.replace(~r/[^a-zA-Z0-9_\-\.]/, "_")

    case Application.get_env(:tiannara, :dets_base_path) do
      nil -> path("dets/#{safe_name}.dets")
      base -> Path.join([base, "dets", to_string(context()), "#{safe_name}.dets"])
    end
  end
end
