defmodule Tiannara.ASC.Adoption.Gate do
  @moduledoc """
  Human-authorization verification. Required fields, exact DECISION string,
  no placeholder values, parseable ISO date. Anything malformed aborts
  loudly — ambiguity never authorizes.
  """

  @required ~w(MISSION CANDIDATE BRANCH DECISION DATE HUMAN)

  def verify(path) do
    with {:ok, text} <- read(path),
         {:ok, fields} <- parse(text),
         {:ok, fields} <- reject_placeholders(fields),
         :ok <- check_date(fields),
         :ok <- check_decision(fields) do
      {:ok, fields}
    end
  end

  defp read(path) do
    if File.exists?(path), do: {:ok, File.read!(path)}, else: {:error, {:authorization_file_missing, path}}
  end

  defp parse(text) do
    fields =
      for line <- String.split(text, "\n"),
          match = Regex.run(~r/^([A-Z_]+):\s*(.+)$/, String.trim(line)),
          match != nil,
          into: %{} do
        [_, k, v] = match
        {k, String.trim(v)}
      end

    missing = @required -- Map.keys(fields)
    if missing == [], do: {:ok, fields}, else: {:error, {:missing_fields, missing}}
  end

  defp reject_placeholders(fields) do
    bad = for {k, v} <- fields, String.match?(v, ~r/^<.*>$/), do: k
    if bad == [], do: {:ok, fields}, else: {:error, {:placeholder_values, bad}}
  end

  defp check_date(%{"DATE" => d}) do
    case Date.from_iso8601(d) do
      {:ok, _} -> :ok
      _ -> {:error, {:invalid_date, d}}
    end
  end

  defp check_decision(%{"DECISION" => "AUTHORIZE_ADOPTION"} = f), do: {:ok, f}
  defp check_decision(f), do: {:error, {:decision_not_authorization, f["DECISION"]}}
end