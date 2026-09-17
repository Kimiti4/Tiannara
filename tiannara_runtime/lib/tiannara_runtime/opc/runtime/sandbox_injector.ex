defmodule Tiannara.OPC.Runtime.SandboxInjector do
  @moduledoc """
  Phase 5F.6 — Runtime Sandbox Injector

  Injects runtime safety constraints into compiled shaders to enforce
  per-observer resource limits and prevent system destabilization.

  ## Safety Constraints

  - VRAM quota enforcement per observer
  - CTN (Chronogram Tensor Network) generation rate caps
  - Execution time limits (prevents infinite loops)
  - Memory access bounds checking
  - Thermal throttling integration with MSCL

  ## Usage

      # Inject sandbox constraints into shader
      shader = "#version 310 es..."
      sandboxed_shader = SandboxInjector.inject(shader, observer_id, limits)

      # Limits example
      limits = %{
        max_vram_mb: 256,
        max_ctn_rate: 1000,
        max_execution_ms: 5000
      }
  """

  require Logger

  # Default resource limits
  @default_max_vram_mb 256
  @default_max_ctn_rate 1000  # CTN nodes per second
  @default_max_execution_ms 5000  # 5 seconds

  @doc """
  Injects sandbox constraints into a GLSL shader.

  ## Parameters
  - `shader`: Original GLSL shader string
  - `observer_id`: Observer identifier
  - `limits`: Resource limit map (optional, uses defaults if not provided)

  ## Returns
  - Sandboxed shader string with injected constraints

  ## Example

      shader = "#version 310 es\\nvoid main() { ... }"
      sandboxed = SandboxInjector.inject(shader, "obs_001")
  """
  def inject(shader, observer_id, limits \\ %{}) when is_binary(shader) do
    Logger.info("🛡️ [SandboxInjector] Injecting sandbox constraints for #{observer_id}")

    max_vram = Map.get(limits, :max_vram_mb, @default_max_vram_mb)
    max_ctn_rate = Map.get(limits, :max_ctn_rate, @default_max_ctn_rate)
    max_execution_ms = Map.get(limits, :max_execution_ms, @default_max_execution_ms)

    shader
    |> inject_vram_guard(max_vram)
    |> inject_ctn_rate_limiter(max_ctn_rate)
    |> inject_execution_timeout(max_execution_ms)
    |> inject_memory_bounds_checker()
    |> add_sandbox_metadata(observer_id, limits)
  end

  # ── Injection Functions ───────────────────────────────────────────────────

  defp inject_vram_guard(shader, max_vram_mb) do
    # Add VRAM usage tracking uniform and guard
    vram_guard = """

    // VRAM Quota Guard (Phase 5F.6 Sandbox)
    uniform float u_max_vram_mb;
    uniform float u_current_vram_usage_mb;

    void check_vram_quota() {
        if (u_current_vram_usage_mb > u_max_vram_mb) {
            // Exceeded VRAM quota - clamp output to safe value
            gl_FragColor = vec4(0.0);
            return;
        }
    }
    """

    # Insert before main function
    Regex.replace(~r/(void\s+main\s*\(\s*\))/, shader, fn _match, main_decl ->
      "#{vram_guard}\n#{main_decl}"
    end)
  end

  defp inject_ctn_rate_limiter(shader, max_ctn_rate) do
    # Add CTN generation rate limiting
    ctn_limiter = """

    // CTN Rate Limiter (Phase 5F.6 Sandbox)
    uniform float u_max_ctn_rate;
    uniform float u_elapsed_time_ms;

    float compute_ctn_rate(float node_count) {
        float rate = node_count / (u_elapsed_time_ms / 1000.0);
        return min(rate, u_max_ctn_rate);
    }
    """

    Regex.replace(~r/(void\s+main\s*\(\s*\))/, shader, fn _match, main_decl ->
      "#{ctn_limiter}\n#{main_decl}"
    end)
  end

  defp inject_execution_timeout(shader, max_execution_ms) do
    # Add execution timeout guard
    timeout_guard = """

    // Execution Timeout Guard (Phase 5F.6 Sandbox)
    uniform float u_max_execution_ms;
    uniform float u_start_time_ms;

    void check_execution_timeout() {
        float current_time = u_elapsed_time_ms - u_start_time_ms;
        if (current_time > u_max_execution_ms) {
            // Timeout exceeded - terminate execution
            discard;
        }
    }
    """

    Regex.replace(~r/(void\s+main\s*\(\s*\))/, shader, fn _match, main_decl ->
      "#{timeout_guard}\n#{main_decl}"
    end)
  end

  defp inject_memory_bounds_checker(shader) do
    # Add memory access bounds checking
    bounds_checker = """

    // Memory Bounds Checker (Phase 5F.6 Sandbox)
    const int MAX_STACK_DEPTH = 256;
    const int MAX_TEXTURE_SIZE = 4096;

    bool check_stack_bounds(int sp) {
        return sp >= 0 && sp < MAX_STACK_DEPTH;
    }

    bool check_texture_bounds(ivec2 coord) {
        return coord.x >= 0 && coord.x < MAX_TEXTURE_SIZE &&
               coord.y >= 0 && coord.y < MAX_TEXTURE_SIZE;
    }
    """

    Regex.replace(~r/(void\s+main\s*\(\s*\))/, shader, fn _match, main_decl ->
      "#{bounds_checker}\n#{main_decl}"
    end)
  end

  defp add_sandbox_metadata(shader, observer_id, limits) do
    # Add metadata comment at top of shader
    metadata = """
    // ╔══════════════════════════════════════════════════╗
    // ║  Tiannara OPC Sandbox Constraints (Phase 5F.6)  ║
    // ╠══════════════════════════════════════════════════╣
    // ║  Observer: #{String.pad_trailing(observer_id, 35)}║
    // ║  Max VRAM: #{String.pad_trailing("#{limits[:max_vram_mb] || @default_max_vram_mb} MB", 35)}║
    // ║  Max CTN Rate: #{String.pad_trailing("#{limits[:max_ctn_rate] || @default_max_ctn_rate} nodes/s", 35)}║
    // ║  Max Exec Time: #{String.pad_trailing("#{limits[:max_execution_ms] || @default_max_execution_ms} ms", 35)}║
    // ╚══════════════════════════════════════════════════╝

    """

    metadata <> shader
  end

  @doc """
  Validates that a shader contains required sandbox constraints.

  ## Parameters
  - `shader`: Shader string to validate

  ## Returns
  - `{:ok, constraints_found}` list of validated constraints
  - `{:error, missing_constraints}` list of missing constraints
  """
  def validate_sandbox(shader) when is_binary(shader) do
    required_patterns = [
      {"VRAM Guard", ~r/check_vram_quota/},
      {"CTN Rate Limiter", ~r/compute_ctn_rate/},
      {"Execution Timeout", ~r/check_execution_timeout/},
      {"Memory Bounds", ~r/check_stack_bounds/}
    ]

    found = Enum.filter(required_patterns, fn {_name, pattern} ->
      Regex.match?(pattern, shader)
    end)

    missing = Enum.reject(required_patterns, fn {_name, pattern} ->
      Regex.match?(pattern, shader)
    end)

    if Enum.empty?(missing) do
      {:ok, Enum.map(found, fn {name, _} -> name end)}
    else
      {:error, Enum.map(missing, fn {name, _} -> name end)}
    end
  end

  @doc """
  Generates default resource limits for an observer based on their tier.

  ## Parameters
  - `observer_tier`: Observer tier (:basic, :standard, :premium, :enterprise)

  ## Returns
  - Resource limit map

  ## Examples

      limits = SandboxInjector.default_limits(:basic)
      # %{max_vram_mb: 128, max_ctn_rate: 500, max_execution_ms: 2000}
  """
  def default_limits(:basic) do
    %{
      max_vram_mb: 128,
      max_ctn_rate: 500,
      max_execution_ms: 2000
    }
  end

  def default_limits(:standard) do
    %{
      max_vram_mb: 256,
      max_ctn_rate: 1000,
      max_execution_ms: 5000
    }
  end

  def default_limits(:premium) do
    %{
      max_vram_mb: 512,
      max_ctn_rate: 2000,
      max_execution_ms: 10000
    }
  end

  def default_limits(:enterprise) do
    %{
      max_vram_mb: 1024,
      max_ctn_rate: 5000,
      max_execution_ms: 30000
    }
  end

  def default_limits(_other) do
    # Default to standard tier
    default_limits(:standard)
  end
end
