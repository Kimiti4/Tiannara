defmodule Tiannara.LEOC.Decoder do
  @moduledoc """
  Deterministic LEOC reconstruction.

  Reconstruction is explicitly marked lossy unless the stored error is zero.
  """
  def reconstruct(%Tiannara.LEOC.Seed{} = seed) do
    with {:ok, baseline_record} <-
           Tiannara.LEOC.AnchorRegistry.get(seed.world_id, seed.baseline_hash),
         {:ok, basis_record} <- Tiannara.LEOC.BasisRegistry.get(seed.basis_hash) do
      latent =
        Nx.from_binary(seed.latent_binary, {:f, 32})
        |> Nx.reshape(seed.latent_shape)

      delta =
        latent
        |> Nx.dot(Nx.transpose(basis_record.basis))
        |> Nx.add(basis_record.mean)

      state =
        baseline_record.tensor
        |> normalize()
        |> Nx.add(delta)
        |> Nx.reshape(baseline_record.tensor.shape)

      {:ok,
       %{
         state: state,
         reconstruction_mse: seed.reconstruction_mse,
         exact: seed.reconstruction_mse == 0.0,
         baseline_hash: seed.baseline_hash,
         basis_hash: seed.basis_hash
       }}
    end
  end

  defp normalize(%Nx.Tensor{shape: shape} = tensor) do
    dims = Tuple.to_list(shape)
    features = List.last(dims)
    samples = div(Enum.reduce(dims, 1, &*/2), features)
    Nx.reshape(tensor, {samples, features})
  end
end
