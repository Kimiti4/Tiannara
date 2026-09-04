defmodule Tiannara.MockAudit do
  @moduledoc """
  A permanent engine scanning the codebase for computational, dashboard,
  and reality mocks to calculate Mock Debt Score and Grounding Progress.
  """

  @derive Jason.Encoder
  defstruct [
    :modules_scanned,
    :mock_occurrences,
    :grounded_occurrences,
    :grounding_percent,
    :mock_occurrences_details # list of map: [%{file: "...", line: 12, query: "...", match: "..."}]
  ]

  @type t :: %__MODULE__{
    modules_scanned: integer(),
    mock_occurrences: integer(),
    grounded_occurrences: integer(),
    grounding_percent: float(),
    mock_occurrences_details: [map()]
  }

  @queries [
    "Enum.random",
    ":rand",
    "random_uniform",
    "mock_",
    "stub_",
    "placeholder",
    "hardcoded"
  ]

  @doc """
  Runs the audit on `lib/` (excluding third-party folders) and returns the report.
  """
  @spec run_audit() :: t()
  def run_audit do
    target_dir = Path.expand("lib/tiannara", File.cwd!())
    
    # List all Elixir source files recursively
    files = list_files_recursive(target_dir)
    modules_scanned = length(files)

    # Search each file for mock terms
    details = 
      Enum.flat_map(files, fn file ->
        scan_file(file)
      end)

    mock_count = length(details)
    
    # Grounded occurrences count lines of code not containing mocks
    total_lines =
      Enum.reduce(files, 0, fn file, acc ->
        case File.read(file) do
          {:ok, content} ->
            acc + (content |> String.split("\n") |> Enum.count(fn line -> String.trim(line) != "" end))
          _ -> acc
        end
      end)

    grounded_occurrences = max(0, total_lines - mock_count)
    grounding_percent =
      if total_lines > 0 do
        Float.round((grounded_occurrences / total_lines) * 100, 2)
      else
        100.0
      end

    %__MODULE__{
      modules_scanned: modules_scanned,
      mock_occurrences: mock_count,
      grounded_occurrences: grounded_occurrences,
      grounding_percent: grounding_percent,
      mock_occurrences_details: details
    }
  end

  defp list_files_recursive(dir) do
    if File.dir?(dir) do
      dir
      |> File.ls!()
      |> Enum.flat_map(fn child ->
        full_path = Path.join(dir, child)
        if File.dir?(full_path) do
          list_files_recursive(full_path)
        else
          if String.ends_with?(full_path, ".ex") or String.ends_with?(full_path, ".exs") do
            [full_path]
          else
            []
          end
        end
      end)
    else
      []
    end
  end

  defp scan_file(file) do
    case File.read(file) do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.flat_map(fn {line_content, line_num} ->
          matching_query = Enum.find(@queries, fn q -> String.contains?(line_content, q) end)
          
          if matching_query do
            [%{
              file: Path.relative_to_cwd(file),
              line: line_num,
              query: matching_query,
              match: String.trim(line_content)
            }]
          else
            []
          end
        end)
      _ ->
        []
    end
  end
end
