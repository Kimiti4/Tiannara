defmodule TiannaraRuntime.CrossDimensional.Compiler do
  @moduledoc """
  Phase 5F.12 — CrossDimensional Compiler

  Translates OPC rule ASTs into latent meta-ops suitable for execution inside
  DFG manifolds while preserving conservation and anchor invariants.
  """

  use GenServer
  require Logger
  alias TiannaraRuntime.CrossDimensional.{BoundaryValidator, MetaOpBytecode, PortalProtocol}
  alias TiannaraRuntime.Topology.PersistentHomology
  alias TiannaraRuntime.ACF.Auditor

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{compiled: 0}}
  end

  @doc "Compile an OPC AST into a DFG meta-op payload."
  def compile(opc_ast, opts \\ %{}) when is_map(opc_ast) do
    meta_op = %{
      id: Map.get(opc_ast, :id, "opc_#{System.unique_integer([:positive])}"),
      source: opc_ast,
      latent_coordinates: project_to_latent_coordinates(opc_ast, opts),
      anchors: extract_anchors(opc_ast),
      cost_estimate: estimate_cost(opc_ast),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case BoundaryValidator.validate(meta_op) do
      :ok ->
        case Auditor.audit(meta_op) do
          :ok ->
            bytecode = MetaOpBytecode.emit(meta_op)
            PortalProtocol.publish(meta_op, bytecode)
            {:ok, meta_op}

          {:reject, reason} ->
            Logger.warning(
              "[CrossDimensional] Meta-op rejected by ACF auditor: #{inspect(reason)}"
            )

            {:error, reason}
        end

      {:error, reason} ->
        Logger.warning(
          "[CrossDimensional] Meta-op failed boundary validation: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp project_to_latent_coordinates(opc_ast, _opts) do
    features =
      PersistentHomology.extract_persistent_features(
        Map.get(opc_ast, :graph, %{nodes: [], edges: []})
      )

    %{
      anchor_count: length(features.anchors),
      localize: Map.take(opc_ast, [:operator, :operands]),
      projected_at: System.system_time(:millisecond)
    }
  end

  defp extract_anchors(opc_ast) do
    Map.get(opc_ast, :anchors, [])
  end

  defp estimate_cost(opc_ast) do
    Map.get(opc_ast, :complexity, 1) * 0.1
  end
end
