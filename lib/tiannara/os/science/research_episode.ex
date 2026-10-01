defmodule TiannaraOS.Science.ResearchEpisode do
  @moduledoc "Research episode lifecycle; persistence is explicit and never implied."

  defstruct [:episode_id, :title, :status, :start_time, :end_time, :results]
  @type episode_id :: String.t()

  def start_episode(params) when is_map(params) do
    id = Map.get(params, :episode_id) || "episode_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
    {:ok, id}
  end

  def start_episode(_), do: {:error, :invalid_parameters}

  def complete_episode(_episode_id, _results), do: {:error, :episode_store_unavailable}

  def get_episode_results(_episode_id), do: {:error, :episode_store_unavailable}
end
