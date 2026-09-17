defmodule ObservatoryCore.Config do
  @moduledoc """
  Constitutional Configuration System (CCS).

  Every configuration is a constitutional artifact:
    id — version — created_at — checksum — signature — source — environment — parent_version — effective_from

  Supports rollback, replay, archaeology, and certification.
  """
  require Logger

  alias ObservatoryCore.Config.Artifact

  @otp_app :observatory_core

  def load! do
    Application.load(@otp_app)
    base = Application.get_env(@otp_app, [])
    env_overrides = load_from_env()
    shadow = load_shadow()
    merged = deep_merge(base, deep_merge(env_overrides, shadow))
    validate_or_crash(merged)
    store_artifact(merged)
    merged
  end

  def get(key, default \\ nil), do: Application.get_env(@otp_app, key, default)

  def env, do: get(:env, :dev)

  def load_shadow do
    if env() == :prod, do: Logger.warning("Remote config shadow unavailable (not implemented)")
    %{}
  end

  defp load_from_env do
    %{
      env: maybe_atom(System.get_env("OBSERVATORY_ENV")),
      database_url: System.get_env("OBSERVATORY_DATABASE_URL"),
      jwt_secret: System.get_env("OBSERVATORY_JWT_SECRET"),
      redis_url: System.get_env("OBSERVATORY_REDIS_URL")
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp maybe_atom(nil), do: nil
  defp maybe_atom("development"), do: :dev
  defp maybe_atom("test"), do: :test
  defp maybe_atom("production"), do: :prod
  defp maybe_atom(_), do: :dev

  defp validate_or_crash(config) do
    with {:ok, validated} <- Artifact.ArtifactValidator.validate(config) do
      Enum.each(validated, fn {key, val} -> Application.put_env(@otp_app, key, val) end)
    else
      {:error, errors} ->
        IO.puts("[CCS] Config validation failed:")
        Enum.each(errors, fn e -> IO.puts("  #{inspect(e)}") end)
        raise "CCS validation fatal"
    end
  end

  defp store_artifact(config) do
    artifact = Artifact.new(config, source: "loader", environment: env())
    :ets.insert(:obs_config_artifacts, {artifact.id, artifact})
    artifact
  end

  defp deep_merge(a, b) when is_map(a) and is_map(b),
    do:
      Map.merge(a, b, fn _k, v1, v2 ->
        if is_map(v1) and is_map(v2), do: deep_merge(v1, v2), else: v2
      end)

  defp deep_merge(a, _b), do: a
end
