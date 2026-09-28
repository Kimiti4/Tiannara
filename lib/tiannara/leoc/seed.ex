defmodule Tiannara.LEOC.Seed do
  @moduledoc """
  Compact, content-addressed LEOC reconstruction seed.
  """

  @enforce_keys [:id, :world_id, :epoch, :latent_binary, :latent_shape, :baseline_hash, :basis_hash]
  defstruct [
    :id,
    :world_id,
    :epoch,
    :latent_binary,
    :latent_shape,
    :baseline_hash,
    :basis_hash,
    :source_state_hash,
    :reconstruction_mse,
    schema_version: 1
  ]

  @type t :: %__MODULE__{
          id: binary(),
          world_id: term(),
          epoch: integer(),
          latent_binary: binary(),
          latent_shape: tuple(),
          baseline_hash: binary(),
          basis_hash: binary(),
          source_state_hash: binary() | nil,
          reconstruction_mse: float() | nil,
          schema_version: pos_integer()
        }
end
