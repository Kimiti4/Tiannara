defmodule TiannaraRuntime.CTL.Event do
  @moduledoc """
  CTL event representation for causal tensegrity processing.

  Events are soft causal nodes with elastic links and optional payload metadata.
  """

   @derive {Jason.Encoder, only: [:id, :timestamp, :causal_links, :payload, :entropy]}
   defstruct [:id, :timestamp, :causal_links, payload: %{}, entropy: nil]

   @type t :: %__MODULE__{
           id: term(),
          timestamp: integer(),
          causal_links: [map()],
          payload: map(),
          entropy: any()
        }

  @doc "Normalize an event payload into a CTL event struct."
  def normalize(%{id: id, timestamp: timestamp} = attrs) do
    %__MODULE__{
      id: id,
      timestamp: timestamp,
      causal_links: Map.get(attrs, :causal_links, []),
      payload: Map.get(attrs, :payload, %{}),
      entropy: Map.get(attrs, :entropy, nil)
    }
  end

  def normalize(%{id: id} = attrs) do
    %__MODULE__{
      id: id,
      timestamp: Map.get(attrs, :timestamp, System.system_time(:millisecond)),
      causal_links: Map.get(attrs, :causal_links, []),
      payload: Map.get(attrs, :payload, %{}),
      entropy: Map.get(attrs, :entropy, nil)
    }
  end

  def normalize(_other) do
    %__MODULE__{
      id: :unknown,
      timestamp: System.system_time(:millisecond),
      causal_links: [],
      payload: %{}
    }
  end
end
