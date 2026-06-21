defmodule Tiannara.ASC.Crucible.FailureClassifier do
  @moduledoc """
  Hierarchical failure classification system for repair pattern matching.
  
  Instead of exact string matching on failure evidence, this module classifies
  failures into a hierarchy of categories and subcategories, enabling semantic
  pattern reuse across similar (but not identical) failures.
  
  Classification Hierarchy:
  
  Level 1 - Domain (origin):
    :requirements, :architecture, :interface, :implementation, :deployment, :operations
  
  Level 2 - Category (failure type):
    :validation, :boundary, :null_safety, :concurrency, :resource, :security, 
    :configuration, :logic, :integration, :performance
  
  Level 3 - Subcategory (specific pattern):
    e.g., :boundary_value, :off_by_one, :uninitialized, :race_condition, etc.
  
  This enables matching patterns like:
    "Boundary value caused unexpected behavior" 
    "Boundary values trigger edge cases"
    "Edge case at boundary condition"
    
  All map to: {:implementation, :boundary, :boundary_value}
  """

  @type classification :: %{
    domain: atom(),
    category: atom(),
    subcategory: atom(),
    confidence: float(),
    keywords: [String.t()]
  }

  @doc """
  Classify a failure observation into hierarchical categories.
  
  ## Parameters
    - observation: The failure observation with evidence
    - project_id: Optional project context
  
  ## Returns
    A classification map with domain, category, subcategory, and confidence
  """
  def classify(%{evidence: evidence, origin: origin} = _observation, project_id \\ nil) do
    domain = classify_domain(origin)
    
    # Extract text from evidence (first evidence item or concatenated)
    evidence_text = extract_evidence_text(evidence)
    
    {category, subcategory, confidence, keywords} = classify_failure_type(evidence_text, domain)
    # Extract variant ID if present
    variant_id = case Regex.run(~r/\[VARIANT: ([^\]]+)\]/, evidence_text) do
      [_, vid] -> vid
      _ -> "generic"
    end
    
    %{
      domain: domain,
      category: category,
      subcategory: subcategory,
      confidence: confidence,
      keywords: keywords,
      # Generate a stable signature from the classification using the controlled vocabulary variant
      signature: "#{domain}:#{category}:#{subcategory}:#{variant_id}"
    }
  end

  @doc """
  Check if two classifications are semantically similar enough for pattern reuse.
  
  ## Matching Rules
    - Exact match on domain + category + subcategory: HIGH confidence reuse
    - Match on domain + category (different subcategory): MEDIUM confidence reuse
    - Match on domain only (different category): LOW confidence reuse
    - No match: No reuse
  
  ## Returns
    {:match, confidence_level} or :no_match
  """
  def similarity_check(%{domain: d1, category: c1, subcategory: s1}, 
                       %{domain: d2, category: c2, subcategory: s2}) do
    cond do
      # Exact match - highest confidence
      d1 == d2 and c1 == c2 and s1 == s2 ->
        {:match, :high}
      
      # Same domain and category, different subcategory - medium confidence
      d1 == d2 and c1 == c2 ->
        {:match, :medium}
      
      # Same domain only - low confidence (only for broad categories)
      d1 == d2 and is_broad_category?(c1) and is_broad_category?(c2) ->
        {:match, :low}
      
      # No meaningful match
      true ->
        :no_match
    end
  end

  @doc """
  Generate a human-readable description of the classification.
  """
  def describe(%{domain: domain, category: category, subcategory: subcategory}) do
    "#{describe_domain(domain)} → #{describe_category(category)} → #{describe_subcategory(subcategory)}"
  end

  # ============================================================================
  # Private Implementation
  # ============================================================================

  defp classify_domain(:requirements), do: :requirements
  defp classify_domain(:architecture), do: :architecture
  defp classify_domain(:interface), do: :interface
  defp classify_domain(:implementation), do: :implementation
  defp classify_domain(:deployment), do: :deployment
  defp classify_domain(:operations), do: :operations
  defp classify_domain(_), do: :unknown

  defp extract_evidence_text(evidence) when is_list(evidence) do
    case evidence do
      [first | _] when is_binary(first) -> first
      _ -> ""
    end
  end
  defp extract_evidence_text(text) when is_binary(text), do: text
  defp extract_evidence_text(_), do: ""

  defp classify_failure_type(text, domain) do
    text_lower = String.downcase(text)
    
    # Try to match specific failure patterns
    cond do
      # Boundary-related failures
      matches_boundary?(text_lower) ->
        subcat = determine_boundary_subtype(text_lower)
        {:boundary, subcat, 0.9, extract_keywords(text_lower, :boundary)}
      
      # Null/nil safety failures
      matches_null_safety?(text_lower) ->
        subcat = determine_null_subtype(text_lower)
        {:null_safety, subcat, 0.85, extract_keywords(text_lower, :null_safety)}
      
      # Validation failures
      matches_validation?(text_lower) ->
        subcat = determine_validation_subtype(text_lower)
        {:validation, subcat, 0.85, extract_keywords(text_lower, :validation)}
      
      # Concurrency failures
      matches_concurrency?(text_lower) ->
        subcat = determine_concurrency_subtype(text_lower)
        {:concurrency, subcat, 0.8, extract_keywords(text_lower, :concurrency)}
      
      # Resource management failures
      matches_resource?(text_lower) ->
        subcat = determine_resource_subtype(text_lower)
        {:resource, subcat, 0.8, extract_keywords(text_lower, :resource)}
      
      # Security failures
      matches_security?(text_lower) ->
        subcat = determine_security_subtype(text_lower)
        {:security, subcat, 0.9, extract_keywords(text_lower, :security)}
      
      # Configuration failures
      matches_configuration?(text_lower) ->
        subcat = determine_configuration_subtype(text_lower)
        {:configuration, subcat, 0.75, extract_keywords(text_lower, :configuration)}
      
      # Logic errors
      matches_logic?(text_lower) ->
        subcat = determine_logic_subtype(text_lower)
        {:logic, subcat, 0.7, extract_keywords(text_lower, :logic)}
      
      # Integration failures
      matches_integration?(text_lower) ->
        subcat = determine_integration_subtype(text_lower)
        {:integration, subcat, 0.75, extract_keywords(text_lower, :integration)}
      
      # Performance issues
      matches_performance?(text_lower) ->
        subcat = determine_performance_subtype(text_lower)
        {:performance, subcat, 0.8, extract_keywords(text_lower, :performance)}
      
      # Default fallback
      true ->
        {:unknown, :generic, 0.5, []}
    end
  end

  # ============================================================================
  # Pattern Matchers
  # ============================================================================

  defp matches_boundary?(text) do
    String.contains?(text, ["boundary", "edge case", "limit", "overflow", "underflow", 
                            "out of range", "index out of bounds"])
  end

  defp matches_null_safety?(text) do
    String.contains?(text, ["null", "nil", "undefined", "not initialized", "uninitialized",
                            "missing value", "empty reference"])
  end

  defp matches_validation?(text) do
    String.contains?(text, ["invalid", "validation", "malformed", "incorrect format",
                            "does not match", "constraint violation"])
  end

  defp matches_concurrency?(text) do
    String.contains?(text, ["race condition", "deadlock", "concurrent", "thread",
                            "synchronization", "mutex", "atomic"])
  end

  defp matches_resource?(text) do
    String.contains?(text, ["memory leak", "resource leak", "file descriptor",
                            "connection pool", "out of memory", "disk space"])
  end

  defp matches_security?(text) do
    String.contains?(text, ["injection", "xss", "csrf", "authentication", "authorization",
                            "privilege escalation", "sql injection", "token forgery"])
  end

  defp matches_configuration?(text) do
    String.contains?(text, ["config", "environment variable", "setting", "parameter",
                            "misconfigured", "wrong configuration"])
  end

  defp matches_logic?(text) do
    String.contains?(text, ["logic error", "incorrect calculation", "wrong result",
                            "unexpected behavior", "incorrect assumption"])
  end

  defp matches_integration?(text) do
    String.contains?(text, ["api", "integration", "external service", "timeout",
                            "connection refused", "network error"])
  end

  defp matches_performance?(text) do
    String.contains?(text, ["slow", "timeout", "latency", "performance", "bottleneck",
                            "degraded", "high cpu", "high memory"])
  end

  # ============================================================================
  # Subtype Determiners
  # ============================================================================

  defp determine_boundary_subtype(text) do
    cond do
      String.contains?(text, ["value", "input"]) -> :boundary_value
      String.contains?(text, ["condition", "check"]) -> :boundary_condition
      String.contains?(text, ["index", "array", "list"]) -> :index_bounds
      String.contains?(text, ["overflow"]) -> :numeric_overflow
      String.contains?(text, ["underflow"]) -> :numeric_underflow
      true -> :boundary_generic
    end
  end

  defp determine_null_subtype(text) do
    cond do
      String.contains?(text, ["uninitialized", "not initialized"]) -> :uninitialized
      String.contains?(text, ["optional", "maybe"]) -> :optional_handling
      String.contains?(text, ["default"]) -> :missing_default
      true -> :null_reference
    end
  end

  defp determine_validation_subtype(text) do
    cond do
      String.contains?(text, ["format", "pattern", "regex"]) -> :format_validation
      String.contains?(text, ["range", "min", "max"]) -> :range_validation
      String.contains?(text, ["type", "cast"]) -> :type_validation
      String.contains?(text, ["required", "mandatory"]) -> :required_field
      true -> :validation_generic
    end
  end

  defp determine_concurrency_subtype(text) do
    cond do
      String.contains?(text, ["race"]) -> :race_condition
      String.contains?(text, ["deadlock"]) -> :deadlock
      String.contains?(text, ["livelock"]) -> :livelock
      String.contains?(text, ["starvation"]) -> :resource_starvation
      true -> :concurrency_generic
    end
  end

  defp determine_resource_subtype(text) do
    cond do
      String.contains?(text, ["memory"]) -> :memory_leak
      String.contains?(text, ["file", "descriptor"]) -> :file_descriptor_leak
      String.contains?(text, ["connection", "pool"]) -> :connection_leak
      true -> :resource_generic
    end
  end

  defp determine_security_subtype(text) do
    cond do
      String.contains?(text, ["sql", "injection"]) -> :sql_injection
      String.contains?(text, ["xss", "script"]) -> :xss
      String.contains?(text, ["csrf", "cross-site"]) -> :csrf
      String.contains?(text, ["auth", "login"]) -> :authentication_bypass
      String.contains?(text, ["privilege", "permission"]) -> :privilege_escalation
      String.contains?(text, ["token"]) -> :token_forgery
      true -> :security_generic
    end
  end

  defp determine_configuration_subtype(text) do
    cond do
      String.contains?(text, ["environment", "env"]) -> :env_config
      String.contains?(text, ["database", "db"]) -> :database_config
      String.contains?(text, ["network", "port"]) -> :network_config
      true -> :config_generic
    end
  end

  defp determine_logic_subtype(text) do
    cond do
      String.contains?(text, ["calculation", "math"]) -> :calculation_error
      String.contains?(text, ["off by one", "fencepost"]) -> :off_by_one
      String.contains?(text, ["assumption", "precondition"]) -> :incorrect_assumption
      true -> :logic_generic
    end
  end

  defp determine_integration_subtype(text) do
    cond do
      String.contains?(text, ["timeout"]) -> :timeout
      String.contains?(text, ["refused", "unreachable"]) -> :connection_failure
      String.contains?(text, ["protocol", "version"]) -> :protocol_mismatch
      true -> :integration_generic
    end
  end

  defp determine_performance_subtype(text) do
    cond do
      String.contains?(text, ["cpu"]) -> :cpu_bound
      String.contains?(text, ["memory", "ram"]) -> :memory_bound
      String.contains?(text, ["io", "disk", "network"]) -> :io_bound
      String.contains?(text, ["algorithm", "complexity"]) -> :algorithmic_complexity
      true -> :performance_generic
    end
  end

  # ============================================================================
  # Keyword Extraction
  # ============================================================================

  defp extract_keywords(text, category) do
    # Extract meaningful keywords from the text for additional matching context
    stop_words = ~w(the a an is are was were be been being have has had do does did
                    will would shall should may might can could of in to for on with
                    at by from as into through during before after above below between
                    out off over under again further then once here there when where
                    why how all each every both few more most other some such no nor
                    not only own same so than too very just because but and or if)
    
    text
    |> String.split(~r/[^a-zA-Z0-9_]/, trim: true)
    |> Enum.map(&String.downcase/1)
    |> Enum.reject(fn word -> 
      String.length(word) < 3 or word in stop_words
    end)
    |> Enum.uniq()
    |> Enum.take(5)  # Limit to top 5 keywords
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp is_broad_category?(:logic), do: true
  defp is_broad_category?(:validation), do: true
  defp is_broad_category?(:integration), do: true
  defp is_broad_category?(_), do: false

  defp describe_domain(:requirements), do: "Requirements"
  defp describe_domain(:architecture), do: "Architecture"
  defp describe_domain(:interface), do: "Interface"
  defp describe_domain(:implementation), do: "Implementation"
  defp describe_domain(:deployment), do: "Deployment"
  defp describe_domain(:operations), do: "Operations"
  defp describe_domain(_), do: "Unknown"

  defp describe_category(:boundary), do: "Boundary Conditions"
  defp describe_category(:null_safety), do: "Null Safety"
  defp describe_category(:validation), do: "Validation"
  defp describe_category(:concurrency), do: "Concurrency"
  defp describe_category(:resource), do: "Resource Management"
  defp describe_category(:security), do: "Security"
  defp describe_category(:configuration), do: "Configuration"
  defp describe_category(:logic), do: "Logic Errors"
  defp describe_category(:integration), do: "Integration"
  defp describe_category(:performance), do: "Performance"
  defp describe_category(_), do: "Unknown"

  defp describe_subcategory(:boundary_value), do: "Boundary Value"
  defp describe_subcategory(:boundary_condition), do: "Boundary Condition Check"
  defp describe_subcategory(:index_bounds), do: "Index Out of Bounds"
  defp describe_subcategory(:numeric_overflow), do: "Numeric Overflow"
  defp describe_subcategory(:numeric_underflow), do: "Numeric Underflow"
  defp describe_subcategory(:boundary_generic), do: "Boundary Issue"
  
  defp describe_subcategory(:uninitialized), do: "Uninitialized Value"
  defp describe_subcategory(:optional_handling), do: "Optional Value Handling"
  defp describe_subcategory(:missing_default), do: "Missing Default Value"
  defp describe_subcategory(:null_reference), do: "Null Reference"
  
  defp describe_subcategory(:format_validation), do: "Format Validation"
  defp describe_subcategory(:range_validation), do: "Range Validation"
  defp describe_subcategory(:type_validation), do: "Type Validation"
  defp describe_subcategory(:required_field), do: "Required Field Missing"
  defp describe_subcategory(:validation_generic), do: "Validation Failure"
  
  defp describe_subcategory(:race_condition), do: "Race Condition"
  defp describe_subcategory(:deadlock), do: "Deadlock"
  defp describe_subcategory(:livelock), do: "Livelock"
  defp describe_subcategory(:resource_starvation), do: "Resource Starvation"
  defp describe_subcategory(:concurrency_generic), do: "Concurrency Issue"
  
  defp describe_subcategory(:memory_leak), do: "Memory Leak"
  defp describe_subcategory(:file_descriptor_leak), do: "File Descriptor Leak"
  defp describe_subcategory(:connection_leak), do: "Connection Leak"
  defp describe_subcategory(:resource_generic), do: "Resource Leak"
  
  defp describe_subcategory(:sql_injection), do: "SQL Injection"
  defp describe_subcategory(:xss), do: "Cross-Site Scripting"
  defp describe_subcategory(:csrf), do: "Cross-Site Request Forgery"
  defp describe_subcategory(:authentication_bypass), do: "Authentication Bypass"
  defp describe_subcategory(:privilege_escalation), do: "Privilege Escalation"
  defp describe_subcategory(:token_forgery), do: "Token Forgery"
  defp describe_subcategory(:security_generic), do: "Security Vulnerability"
  
  defp describe_subcategory(:env_config), do: "Environment Configuration"
  defp describe_subcategory(:database_config), do: "Database Configuration"
  defp describe_subcategory(:network_config), do: "Network Configuration"
  defp describe_subcategory(:config_generic), do: "Configuration Error"
  
  defp describe_subcategory(:calculation_error), do: "Calculation Error"
  defp describe_subcategory(:off_by_one), do: "Off-by-One Error"
  defp describe_subcategory(:incorrect_assumption), do: "Incorrect Assumption"
  defp describe_subcategory(:logic_generic), do: "Logic Error"
  
  defp describe_subcategory(:timeout), do: "Timeout"
  defp describe_subcategory(:connection_failure), do: "Connection Failure"
  defp describe_subcategory(:protocol_mismatch), do: "Protocol Mismatch"
  defp describe_subcategory(:integration_generic), do: "Integration Failure"
  
  defp describe_subcategory(:cpu_bound), do: "CPU-Bound Performance"
  defp describe_subcategory(:memory_bound), do: "Memory-Bound Performance"
  defp describe_subcategory(:io_bound), do: "I/O-Bound Performance"
  defp describe_subcategory(:algorithmic_complexity), do: "Algorithmic Complexity"
  defp describe_subcategory(:performance_generic), do: "Performance Degradation"
  
  defp describe_subcategory(_), do: "Generic Issue"
end
