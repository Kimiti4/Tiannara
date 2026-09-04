defmodule Tiannara.EOS.BusSpec do
  @moduledoc """
  Declarative policy for one event domain.
  Constitutional mandate: "Explicit interfaces, minimal coupling."

  Each bus has its own durability, ordering, overflow, and rate-limit policy
  so a noisy domain cannot degrade a critical one.
  """

  @enforce_keys [:name, :durability, :ordering, :overflow_policy]
  defstruct [
    :name,
    :durability,
    :ordering,
    :overflow_policy,
    :max_rate_per_sec,
    :replay_retention,
    :isolation_level
  ]

  @type t :: %__MODULE__{}

  def policies do
    %{
      observation: %__MODULE__{
        name: :observation, durability: :durable, ordering: :causal,
        overflow_policy: :spill_to_disk, max_rate_per_sec: 10_000,
        replay_retention: {:days, 30}, isolation_level: :standard
      },
      theory: %__MODULE__{
        name: :theory, durability: :durable, ordering: :causal,
        overflow_policy: :block, max_rate_per_sec: 1_000,
        replay_retention: :permanent, isolation_level: :critical
      },
      engineering: %__MODULE__{
        name: :engineering, durability: :durable, ordering: :strict,
        overflow_policy: :block, max_rate_per_sec: 500,
        replay_retention: :permanent, isolation_level: :critical
      },
      governance: %__MODULE__{
        name: :governance, durability: :durable, ordering: :strict,
        overflow_policy: :block, max_rate_per_sec: 100,
        replay_retention: :permanent, isolation_level: :critical
      },
      telemetry: %__MODULE__{
        name: :telemetry, durability: :volatile, ordering: :none,
        overflow_policy: :drop_newest, max_rate_per_sec: 100_000,
        replay_retention: :none, isolation_level: :lossy_ok
      }
    }
  end

  @doc "The five legal domain names."
  def domain_names, do: ~w(observation theory engineering governance telemetry)a

  @doc "True if the domain is critical and must never drop events."
  def critical?(:governance), do: true
  def critical?(:engineering), do: true
  def critical?(:theory), do: true
  def critical?(_), do: false
end
