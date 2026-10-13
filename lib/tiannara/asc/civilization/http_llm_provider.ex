defmodule Tiannara.ASC.Civilization.HTTPLLMProvider do
  @moduledoc """
  Phase 9 `LLMProvider` backed by real HTTP inference via `LLMGateway`.

  Select it with:

      config :tiannara, :asc_llm_provider, Tiannara.ASC.Civilization.HTTPLLMProvider

  Requires `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` in the environment (or
  `:llm_mock` for fixture responses). The gateway fails closed when no
  credentials are configured — this provider never fabricates inference.
  """
  @behaviour Tiannara.ASC.Civilization.LLMProvider

  alias Tiannara.ASC.Cognition.LLMGateway
  require Logger

  @design_schema %{
    "type" => "object",
    "required" => ["targets", "rationale"],
    "properties" => %{
      "targets" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "required" => ["file", "strategy"],
          "properties" => %{
            "file" => %{"type" => "string"},
            "strategy" => %{"type" => "string"}
          }
        }
      },
      "rationale" => %{"type" => "string"}
    }
  }

  @patch_schema %{
    "type" => "object",
    "required" => ["patches"],
    "properties" => %{
      "patches" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "required" => ["target_file", "replacement_content"],
          "properties" => %{
            "target_file" => %{"type" => "string"},
            "replacement_content" => %{"type" => "string"},
            "confidence" => %{"type" => "number"}
          }
        }
      }
    }
  }

  @review_schema %{
    "type" => "object",
    "required" => ["verdict", "reasoning"],
    "properties" => %{
      "verdict" => %{"type" => "string", "enum" => ["approved", "rejected"]},
      "reasoning" => %{"type" => "string"}
    }
  }

  @impl true
  def generate_design(goal, genome) do
    prompt = """
    You are a senior software architect inside an autonomous software civilization.

    Goal: #{goal}
    Genome methodology: #{genome.methodology}
    Exploration bias: #{genome.exploration_bias}

    Return strict JSON:
    {
      "targets": [{"file": "...", "strategy": "..."}],
      "rationale": "..."
    }
    """

    case LLMGateway.reason("You are a senior software architect.", prompt, @design_schema, 4_000) do
      {:ok, %{"targets" => targets, "rationale" => rationale}} when is_list(targets) ->
        %{targets: normalize_targets(targets), rationale: rationale}

      {:ok, map} ->
        %{
          targets: normalize_targets(Map.get(map, "targets", [])),
          rationale: Map.get(map, "rationale", "no rationale returned")
        }

      {:error, reason, detail} ->
        Logger.error("❌ [HTTPLLMProvider] design failed: #{inspect(reason)} - #{detail}")
        %{targets: [], rationale: "LLM design failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def generate_patch(design_doc, genome, feedback) do
    target =
      design_doc
      |> Map.get(:targets, [])
      |> case do
        [] -> "unknown"
        targets -> Map.get(hd(targets), :file, "unknown")
      end

    prompt = """
    You are a senior engineer inside an autonomous software civilization.

    Target file: #{target}
    Design doc: #{inspect(design_doc)}
    Genome methodology: #{genome.methodology}
    Review feedback to address: #{inspect(feedback)}

    Return strict JSON:
    {
      "patches": [
        {"target_file": "...", "replacement_content": "...", "confidence": 0.0}
      ]
    }
    """

    case LLMGateway.reason("You are a senior engineer.", prompt, @patch_schema, 8_000) do
      {:ok, %{"patches" => patches}} when is_list(patches) and patches != [] ->
        Enum.map(patches, &normalize_patch/1)

      {:ok, map} ->
        map
        |> Map.get("patches", [])
        |> case do
          [] ->
            Logger.error("❌ [HTTPLLMProvider] LLM returned no patches")
            []

          patches ->
            Enum.map(patches, &normalize_patch/1)
        end

      {:error, reason, detail} ->
        Logger.error(
          "❌ [HTTPLLMProvider] patch generation failed: #{inspect(reason)} - #{detail}"
        )

        []
    end
  end

  @impl true
  def review_patch(design_doc, patches, _genome) do
    prompt = """
    You are a strict code reviewer inside an autonomous software civilization.

    Design doc: #{inspect(design_doc)}
    Patches to review: #{inspect(patches)}

    Return strict JSON:
    {"verdict": "approved" | "rejected", "reasoning": "..."}
    """

    case LLMGateway.reason("You are a strict code reviewer.", prompt, @review_schema, 2_000) do
      {:ok, %{"verdict" => verdict, "reasoning" => reasoning}} ->
        if verdict in ["approved", "approve", "pass"] do
          {:approved, reasoning}
        else
          {:rejected, reasoning}
        end

      {:error, reason, detail} ->
        # Fail closed: no LLM verdict means no approval.
        {:rejected, "LLM review unavailable (#{inspect(reason)}): #{detail}"}
    end
  end

  defp normalize_targets(targets) do
    Enum.map(targets, fn t ->
      %{
        file: fetch(t, :file),
        strategy: fetch(t, :strategy)
      }
    end)
  end

  defp normalize_patch(p) do
    %{
      target_file: fetch(p, :target_file),
      replacement_content: fetch(p, :replacement_content),
      confidence: fetch(p, :confidence) || 0.5
    }
  end

  defp fetch(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
