defmodule Tiannara.BaseReality.Workspace do
  @moduledoc """
  Writes validated synthesis artifacts into a configurable local workspace.

  This module does not initialize repositories, stage files, or create Git
  commits. Artifact generation and source-control approval are separate actions.
  """

  @default_workspace_path Path.join(System.user_home!(), "Tiannara/Deployments")

  @spec write_blueprints([map()], atom() | String.t()) ::
          {:ok, map()} | {:error, term()}
  def write_blueprints(blueprints, intent)
      when is_list(blueprints) and blueprints != [] do
    with :ok <- validate_blueprints(blueprints),
         {:ok, deployment_dir} <- create_deployment_dir(),
         {:ok, files} <- write_files(deployment_dir, blueprints) do
      manifest =
        files
        |> Enum.sort()
        |> Enum.map(fn file ->
          {:ok, content} = File.read(Path.join(deployment_dir, file))
          {file, :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)}
        end)

      manifest_hash =
        :crypto.hash(:sha256, :erlang.term_to_binary({intent, manifest}))
        |> Base.encode16(case: :lower)

      {:ok,
       %{
         status: :artifacts_written,
         directory: deployment_dir,
         files: files,
         manifest_sha256: manifest_hash,
         source_control: :not_committed
       }}
    end
  rescue
    error -> {:error, {:workspace_write_failed, error.__struct__}}
  end

  def write_blueprints([], _intent), do: {:error, :no_validated_blueprints}
  def write_blueprints(_blueprints, _intent), do: {:error, :invalid_blueprints}

  # Compatibility shim for older callers. Despite the historical name, this
  # function intentionally writes files only; it never creates a Git commit.
  def commit_blueprints(blueprints, intent), do: write_blueprints(blueprints, intent)

  defp validate_blueprints(blueprints) do
    if Enum.all?(blueprints, fn
         %{status: :success, domain: domain, schematics: schematics}
         when is_atom(domain) or is_binary(domain) ->
           is_binary(schematics) and String.trim(schematics) != ""

         _ ->
           false
       end) do
      :ok
    else
      {:error, :unvalidated_blueprint}
    end
  end

  defp create_deployment_dir do
    root =
      Application.get_env(:tiannara, :workspace_path, @default_workspace_path)
      |> Path.expand()

    timestamp = System.system_time(:microsecond)
    directory = Path.join(root, "synthesis_#{timestamp}")

    case File.mkdir_p(directory) do
      :ok -> {:ok, directory}
      {:error, reason} -> {:error, {:workspace_directory_unavailable, reason}}
    end
  end

  defp write_files(directory, blueprints) do
    Enum.reduce_while(blueprints, {:ok, []}, fn blueprint, {:ok, written} ->
      filename = safe_domain_name(blueprint.domain) <> "_schematic.v"
      path = Path.join(directory, filename)

      case File.write(path, blueprint.schematics, [:binary, :exclusive]) do
        :ok -> {:cont, {:ok, [filename | written]}}
        {:error, reason} -> {:halt, {:error, {:artifact_write_failed, filename, reason}}}
      end
    end)
    |> case do
      {:ok, files} -> {:ok, Enum.reverse(files)}
      error -> error
    end
  end

  defp safe_domain_name(domain) do
    domain
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_-]+/, "_")
    |> String.trim("_")
    |> case do
      "" -> "unknown_domain"
      name -> name
    end
  end
end
