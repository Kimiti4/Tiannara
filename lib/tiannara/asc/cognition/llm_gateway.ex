defmodule Tiannara.ASC.Cognition.LLMGateway do
  @moduledoc """
  Phase 14: The bridge between the Civilization OS and external Reasoning Engines.
  Handles API calls, token tracking, and strict JSON enforcement.

  Provider selection happens at **runtime** (previously the provider name was a
  compile-time module attribute and the "API call" returned hardcoded fixture
  strings — see the 2026-10-13 doc-vs-reality audit):

    1. `Application.get_env(:tiannara, :llm_mock, false)` is truthy → canned
       fixture responses, loudly logged as mock (config/test.exs sets this).
    2. `ANTHROPIC_API_KEY` present → real HTTPS call to api.anthropic.com.
    3. `OPENAI_API_KEY` present → real HTTPS call to api.openai.com.
    4. Otherwise → `{:error, :no_api_key, ...}` — **fail-closed**, never fake
       inference.

  Returns `{:ok, map}` or `{:error, reason_atom, detail_string}` (contract used
  by CapabilityInventor and AgenticCoder).
  """
  require Logger

  @anthropic_url ~c"https://api.anthropic.com/v1/messages"
  @openai_url ~c"https://api.openai.com/v1/chat/completions"

  @doc """
  Sends a structured prompt to the active reasoning engine and demands a strict
  JSON response. Enforces the Constitution's compute budget via token tracking.
  """
  def reason(system_prompt, user_prompt, json_schema, budget_remaining) do
    provider = active_provider()

    Logger.info(
      "🧠 [LLMGateway] Invoking #{provider} (Budget Remaining: #{budget_remaining} tokens)"
    )

    payload = build_payload(system_prompt, user_prompt, json_schema)

    case execute_api_call(provider, payload) do
      {:ok, raw_json, tokens_used} when is_integer(tokens_used) ->
        if tokens_used > budget_remaining do
          {:error, :budget_exhausted, "LLM exceeded mission compute budget."}
        else
          parse_and_validate(raw_json, json_schema)
        end

      {:error, reason} when is_atom(reason) ->
        {:error, reason, "LLM provider call failed."}

      {:error, reason, detail} when is_atom(reason) ->
        {:error, reason, detail}

      {:error, other} ->
        {:error, :provider_error, inspect(other)}

      unexpected ->
        {:error, :provider_error, "Unexpected provider result: #{inspect(unexpected)}"}
    end
  end

  defp active_provider do
    cond do
      Application.get_env(:tiannara, :llm_mock, false) -> :mock
      System.get_env("ANTHROPIC_API_KEY") not in [nil, ""] -> :anthropic
      System.get_env("OPENAI_API_KEY") not in [nil, ""] -> :openai
      true -> :none
    end
  end

  defp build_payload(sys, user, schema) do
    %{
      system: sys,
      messages: [%{role: "user", content: user}],
      response_format: %{type: "json_object", schema: schema}
    }
  end

  # ---- providers ----------------------------------------------------------

  defp execute_api_call(:mock, payload) do
    Logger.warning(
      "🧠 [LLMGateway] MOCK MODE — returning canned fixture responses (no inference performed). " <>
        "Set ANTHROPIC_API_KEY or OPENAI_API_KEY and unset :llm_mock for real inference."
    )

    system_prompt = payload[:system] || ""

    simulated_response =
      if String.contains?(system_prompt, "elite Elixir/Python software engineer") do
        """
        {
          "diff": "--- a/lib/dummy.ex\\n+++ b/lib/dummy.ex\\n@@ -1,2 +1,2 @@\\n-defmodule Dummy do\\n+defmodule Dummy do\\n   def test, do: :ok\\n end",
          "explanation": "Applied ADR-01 (functional core) by refactoring the module."
        }
        """
      else
        """
        {
          "capability_name": "Dependency Drift Analyst",
          "capability_type": "cognitive_tool",
          "rationale": "Friction indicates silent failures when upstream APIs change schemas without version bumps. Existing roles only check internal logic, not external contract drift.",
          "trigger_condition": {"touches_external_apis": true, "codebase_age": ">6_months"},
          "implementation_strategy": "Fetch historical API contracts from Institutional Memory and diff against current patch dependencies."
        }
        """
      end

    {:ok, simulated_response, 450}
  end

  defp execute_api_call(:none, _payload) do
    {:error, :no_api_key,
     "No LLM credentials configured. Set ANTHROPIC_API_KEY or OPENAI_API_KEY, " <>
       "or enable Application config :tiannara, :llm_mock, true for fixture responses."}
  end

  defp execute_api_call(:anthropic, payload) do
    body = %{
      model: System.get_env("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
      system: payload.system,
      messages: payload.messages,
      max_tokens: 4096
    }

    headers = [
      {~c"x-api-key", to_charlist(System.get_env("ANTHROPIC_API_KEY"))},
      {~c"anthropic-version", ~c"2023-06-01"},
      {~c"content-type", ~c"application/json"}
    ]

    case http_post(@anthropic_url, headers, body) do
      {:ok, %{"content" => [%{"text" => text} | _]} = resp} ->
        usage = Map.get(resp, "usage", %{})
        tokens = Map.get(usage, "input_tokens", 0) + Map.get(usage, "output_tokens", 0)
        {:ok, text, tokens}

      {:ok, other} ->
        {:error, :unexpected_response,
         "Anthropic response shape unexpected: #{truncate(inspect(other))}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp execute_api_call(:openai, payload) do
    body = %{
      model: System.get_env("OPENAI_MODEL", "gpt-4o"),
      messages: [%{role: "system", content: payload.system} | payload.messages],
      response_format: payload.response_format
    }

    headers = [
      {~c"authorization", to_charlist("Bearer #{System.get_env("OPENAI_API_KEY")}")},
      {~c"content-type", ~c"application/json"}
    ]

    case http_post(@openai_url, headers, body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => text}} | _]} = resp} ->
        usage = Map.get(resp, "usage", %{})
        {:ok, text, Map.get(usage, "total_tokens", 0)}

      {:ok, other} ->
        {:error, :unexpected_response,
         "OpenAI response shape unexpected: #{truncate(inspect(other))}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ---- transport (:httpc — :inets/:ssl already in extra_applications) -----

  defp http_post(url, headers, body_map) do
    request = {url, headers, ~c"application/json", Jason.encode!(body_map)}

    cacerts =
      try do
        :public_key.cacerts_get()
      rescue
        _ -> []
      catch
        _, _ -> []
      end

    ssl_opts = [cacerts: cacerts, verify: :verify_peer]
    http_opts = [ssl: ssl_opts, timeout: 60_000, connect_timeout: 15_000]

    case :httpc.request(:post, request, http_opts, body_format: :binary) do
      {:ok, {{_http, 200, _}, _resp_headers, resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, map} -> {:ok, map}
          {:error, _} -> {:error, :invalid_json}
        end

      {:ok, {{_http, status, _}, _resp_headers, resp_body}} ->
        {:error, {:http_error, status, truncate(resp_body)}}

      {:error, reason} ->
        {:error, {:transport_error, reason}}
    end
  end

  defp truncate(bin, limit \\ 300) when is_binary(bin), do: String.slice(bin, 0, limit)
  defp truncate(other, limit), do: other |> inspect() |> truncate(limit)

  # ---- validation ---------------------------------------------------------

  defp parse_and_validate(raw_json, schema) when is_binary(raw_json) do
    case Jason.decode(raw_json) do
      {:ok, map} when is_map(map) ->
        required = schema_required(schema)

        missing = Enum.reject(required, &Map.has_key?(map, &1))

        if missing == [] do
          {:ok, map}
        else
          {:error, :schema_violation, "LLM response missing required keys: #{inspect(missing)}"}
        end

      {:ok, _} ->
        {:error, :invalid_json, "LLM response was not a JSON object."}

      {:error, _} ->
        {:error, :invalid_json, "LLM failed to produce valid JSON."}
    end
  end

  defp schema_required(schema) when is_map(schema) do
    case Map.get(schema, "required") || Map.get(schema, :required) do
      list when is_list(list) -> Enum.map(list, &to_string/1)
      _ -> []
    end
  end

  defp schema_required(_), do: []
end
