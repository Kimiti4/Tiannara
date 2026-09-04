defmodule Tiannara.ASC.Core.Coordinator do
  @moduledoc """
  Boots the required ASC workers through the WorkerSupervisor and exposes
  core health. A worker boot failure crashes the coordinator loudly —
  silent partial boots are a constitution violation.
  """

  use GenServer

  alias Tiannara.ASC.Core.Worker

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def required_workers, do: Application.get_env(:tiannara, :asc_required_workers, [])

  def health do
    required = Enum.map(required_workers(), & &1.role)

    registered =
      required
      |> Enum.filter(fn role -> match?({:ok, _}, Worker.whereis(role)) end)

    %{required: required, registered: registered, missing: required -- registered}
  end

  @impl true
  def init(_opts) do
    bootstrap()
    {:ok, %{bootstrapped_at: System.system_time(:millisecond)}}
  end

  defp bootstrap do
    Enum.each(required_workers(), fn spec ->
      child = %{
        id: spec.role,
        start: {Worker, :start_link, [spec]},
        restart: :transient
      }

      case DynamicSupervisor.start_child(Tiannara.ASC.Core.WorkerSupervisor, child) do
        {:ok, _pid} -> :ok
        {:ok, _pid, _} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        {:error, reason} -> raise "ASC worker #{inspect(spec.role)} failed to boot: #{inspect(reason)}"
      end
    end)
  end
end