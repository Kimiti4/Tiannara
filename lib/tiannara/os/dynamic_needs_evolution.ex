defmodule TiannaraOS.DynamicNeedsEvolution do
  @moduledoc """
  Sprint 2: Dynamic World Needs Evolution
  
  Worlds shift their research priorities as discoveries accumulate:
  - Satisfied needs decrease in priority
  - Oversaturated domains become less valuable
  - Underserved domains emerge as opportunities
  - New needs can emerge from technological progress
  
  This creates genuine co-evolutionary pressure where programs must
  adapt to changing environmental demands.
  """
  

  
  # Rate at which satisfied needs decay (per relevant discovery)
  @satisfaction_decay_rate 0.02
  
  # Minimum need value (needs never go to zero)
  @min_need_value 0.1
  
  # Maximum need value (needs can increase but cap at this)
  @max_need_value 1.0
  
  # Threshold for domain oversaturation
  @oversaturation_threshold 0.3
  
  # Threshold for domain underservice
  @underservice_threshold 0.1
  
  # Emergence multiplier (how fast new needs grow)
  @emergence_multiplier 1.2
  
  @doc """
  Evolve world needs based on accumulated discoveries.
  
  As discoveries address certain needs, those needs decrease.
  Oversaturated domains lose priority while underserved domains gain it.
  
  ## Parameters
  
  - `current_needs`: Current needs vector %{domain => weight}
  - `discoveries`: List of discoveries in this world
  - `tick`: Current simulation tick (for time-based emergence)
  
  ## Returns
  
  Updated needs vector reflecting evolved priorities.
  """
  @spec evolve_needs(map(), [map()], integer()) :: map()
  def evolve_needs(current_needs, discoveries, _tick) do
    if Enum.empty?(discoveries) do
      current_needs
    else
      # Step 1: Reduce needs that have been satisfied by discoveries
      after_satisfaction = reduce_satisfied_needs(current_needs, discoveries)
      
      # Step 2: Detect emerging needs from oversaturation patterns
      emerging_needs = detect_emerging_needs(discoveries, after_satisfaction)
      
      # Step 3: Merge and normalize
      final_needs = merge_and_normalize(after_satisfaction, emerging_needs)
      
      final_needs
    end
  end
  
  @doc false
  @spec reduce_satisfied_needs(map(), [map()]) :: map()
  defp reduce_satisfied_needs(current_needs, discoveries) do
    Enum.reduce(discoveries, current_needs, fn {_disc_id, discovery}, needs_acc ->
      domain_vector = Map.get(discovery.metadata || %{}, :domain_vector, %{})
      
      # For each domain in the discovery's vector
      Enum.reduce(domain_vector, needs_acc, fn {domain, relevance}, acc ->
        if relevance > 0.5 do
          # This discovery addresses this need
          current_need = Map.get(acc, domain, @min_need_value)
          
          # Reduce need by decay rate * relevance
          reduction = @satisfaction_decay_rate * relevance
          new_need = max(@min_need_value, current_need - reduction)
          
          Map.put(acc, domain, Float.round(new_need, 3))
        else
          acc
        end
      end)
    end)
  end
  
  @doc false
  @spec detect_emerging_needs([map()], map()) :: map()
  defp detect_emerging_needs(discoveries, current_needs) do
    # Count discoveries per primary domain
    domain_counts = count_discoveries_by_domain(discoveries)
    
    total_discoveries = Enum.sum(Map.values(domain_counts))
    
    if total_discoveries == 0 do
      %{}
    else
      # Find oversaturated domains
      oversaturated_domains = Enum.filter(domain_counts, fn {_domain, count} ->
        proportion = count / total_discoveries
        proportion > @oversaturation_threshold
      end)
      |> Enum.map(fn {domain, _count} -> domain end)
      
      # Find underserved domains
      underserved_domains = Enum.filter(domain_counts, fn {_domain, count} ->
        proportion = count / total_discoveries
        proportion < @underservice_threshold
      end)
      |> Enum.map(fn {domain, _count} -> domain end)
      
      # Generate emerging needs
      emerging = %{}
      
      # Boost underserved domains
      emerging = Enum.reduce(underserved_domains, emerging, fn domain, acc ->
        current_value = Map.get(current_needs, domain, 0.5)
        boosted_value = min(@max_need_value, current_value * @emergence_multiplier)
        Map.put(acc, domain, Float.round(boosted_value, 3))
      end)
      
      # Add cross-domain opportunities (if energy saturated, boost materials)
      cross_domain_needs = generate_cross_domain_needs(oversaturated_domains, current_needs)
      
      Map.merge(emerging, cross_domain_needs, fn _k, v1, v2 ->
        max(v1, v2)  # Take higher value
      end)
    end
  end
  
  @doc false
  @spec count_discoveries_by_domain([map()]) :: map()
  defp count_discoveries_by_domain(discoveries) do
    Enum.reduce(discoveries, %{}, fn {_disc_id, discovery}, acc ->
      domain_vector = Map.get(discovery.metadata || %{}, :domain_vector, %{})
      
      # Find primary domain (highest weight)
      primary_domain = domain_vector
        |> Enum.max_by(fn {_domain, weight} -> weight end, fn -> {:unknown, 0.0} end)
        |> elem(0)
      
      Map.update(acc, primary_domain, 1, & &1 + 1)
    end)
  end
  
  @doc false
  @spec generate_cross_domain_needs([atom()], map()) :: map()
  defp generate_cross_domain_needs(oversaturated_domains, current_needs) do
    cross_domain_map = %{
      energy: [:materials, :efficiency, :storage],
      materials: [:energy, :synthesis, :recycling],
      medicine: [:prevention, :diagnostics, :genetics],
      prevention: [:medicine, :public_health],
      diagnostics: [:medicine, :imaging],
      genetics: [:medicine, :bioengineering],
      computation: [:algorithms, :hardware],
      cybernetics: [:robotics, :ai, :control_systems],
      robotics: [:cybernetics, :mechanics, :sensors],
      ai: [:cybernetics, :learning, :reasoning],
      physics: [:energy, :materials, :cosmology],
      chemistry: [:materials, :medicine, :energy]
    }
    
    Enum.reduce(oversaturated_domains, %{}, fn domain, acc ->
      related_domains = Map.get(cross_domain_map, domain, [])
      
      Enum.reduce(related_domains, acc, fn related_domain, inner_acc ->
        # Only boost if not already high
        current_value = Map.get(current_needs, related_domain, 0.5)
        
        if current_value < 0.6 do
          # Boost this related domain
          boosted = min(@max_need_value, current_value * 1.15)
          Map.put(inner_acc, related_domain, Float.round(boosted, 3))
        else
          inner_acc
        end
      end)
    end)
  end
  
  @doc """
  Generate emergent needs when existing needs are satisfied.
  
  Solving one problem reveals the next bottleneck.
  Example: Energy solved → Manufacturing becomes bottleneck
  
  ## Parameters
  
  - `original_needs`: Original needs vector at world creation
  - `current_needs`: Current needs after satisfaction decay
  - `discoveries`: List of discoveries that caused satisfaction
  
  ## Returns
  
  Map of newly emerged needs with initial priority values.
  """
  @spec generate_emergent_needs(map(), map(), [map()]) :: map()
  def generate_emergent_needs(original_needs, current_needs, _discoveries) do
    # Identify highly satisfied needs (>70% reduction)
    satisfied_needs = identify_satisfied_needs(original_needs, current_needs)
    
    # For each satisfied need, generate adjacent needs
    emergent = Enum.reduce(satisfied_needs, %{}, fn satisfied_domain, acc ->
      adjacent_needs = get_adjacent_needs(satisfied_domain)
      
      Enum.reduce(adjacent_needs, acc, fn {adjacent_domain, emergence_prob}, inner_acc ->
        # Check if this adjacent need already exists
        if Map.has_key?(current_needs, adjacent_domain) do
          # Boost existing need slightly
          current_value = Map.get(current_needs, adjacent_domain, 0.5)
          boosted = min(1.0, current_value * 1.1)
          Map.put(inner_acc, adjacent_domain, Float.round(boosted, 3))
        else
          # Create new need with emergence probability
          if :rand.uniform() < emergence_prob do
            Map.put(inner_acc, adjacent_domain, 0.4)  # Start at moderate priority
          else
            inner_acc
          end
        end
      end)
    end)
    
    emergent
  end
  
  @doc """
  Define adjacency relationships between needs.
  
  When one need is satisfied, these adjacent needs may emerge.
  Based on historical technological progression patterns.
  
  ## Examples
  
  - energy → materials (need infrastructure to use energy)
  - materials → manufacturing (need to shape materials)
  - medicine → prevention (treatment leads to prevention focus)
  - transportation → urban_planning (mobility enables cities)
  """
  @spec get_adjacent_needs(atom()) :: [{atom(), float()}]
  def get_adjacent_needs(domain) do
    adjacency_map = %{
      energy: [
        {:materials, 0.6},      # Energy → need materials to build infrastructure
        {:efficiency, 0.5},     # Energy → need efficiency to optimize usage
        {:storage, 0.7}         # Energy → need storage for intermittency
      ],
      materials: [
        {:energy, 0.4},         # Materials → need energy for processing
        {:manufacturing, 0.8},  # Materials → need manufacturing to shape them
        {:recycling, 0.5}       # Materials → need recycling for sustainability
      ],
      medicine: [
        {:prevention, 0.7},     # Medicine → prevention becomes valuable
        {:diagnostics, 0.8},    # Medicine → better diagnostics needed
        {:genetics, 0.6},       # Medicine → genetic understanding emerges
        {:public_health, 0.5}   # Medicine → population-level health
      ],
      manufacturing: [
        {:automation, 0.9},     # Manufacturing → automation to scale
        {:logistics, 0.7},      # Manufacturing → need distribution
        {:quality_control, 0.6} # Manufacturing → need quality assurance
      ],
      transportation: [
        {:urban_planning, 0.8}, # Transportation → cities form
        {:infrastructure, 0.7}, # Transportation → need roads/ports
        {:energy, 0.6}          # Transportation → fuel requirements
      ],
      computation: [
        {:algorithms, 0.8},     # Computation → need better algorithms
        {:hardware, 0.7},       # Computation → need faster hardware
        {:ai, 0.6},             # Computation → AI becomes possible
        {:data_science, 0.5}    # Computation → data analysis emerges
      ]
    }
    
    Map.get(adjacency_map, domain, [])
  end
  
  @doc false
  @spec identify_satisfied_needs(map(), map()) :: [atom()]
  defp identify_satisfied_needs(original_needs, current_needs) do
    Enum.filter(original_needs, fn {domain, original_value} ->
      current_value = Map.get(current_needs, domain, original_value)
      reduction = (original_value - current_value) / original_value
      reduction > 0.7  # 70% satisfaction threshold
    end)
    |> Enum.map(fn {domain, _value} -> domain end)
  end
  
  @doc false
  @spec merge_and_normalize(map(), map()) :: map()
  defp merge_and_normalize(current_needs, emerging_needs) do
    merged = Map.merge(current_needs, emerging_needs, fn _key, current_val, emerging_val ->
      # Take max, but allow some decay from current
      max(current_val * 0.95, emerging_val)
    end)
    
    # Ensure all values bounded
    Enum.reduce(merged, %{}, fn {domain, value}, acc ->
      bounded = max(@min_need_value, min(@max_need_value, value))
      Map.put(acc, domain, Float.round(bounded, 3))
    end)
  end
  
  @doc """
  Calculate need satisfaction level for reporting.
  
  Returns percentage of needs that have been significantly addressed.
  """
  @spec calculate_satisfaction_level(map(), map()) :: float()
  def calculate_satisfaction_level(original_needs, current_needs) do
    if map_size(original_needs) == 0 do
      0.0
    else
      reductions = Enum.map(original_needs, fn {domain, original_value} ->
        current_value = Map.get(current_needs, domain, original_value)
        reduction = (original_value - current_value) / original_value
        max(0.0, reduction)  # Only count positive reductions
      end)
      
      avg_reduction = Enum.sum(reductions) / length(reductions)
      Float.round(avg_reduction * 100, 1)  # Convert to percentage
    end
  end
  
  @doc """
  Summarize needs evolution for reporting.
  
  Returns human-readable summary of how needs have changed.
  """
  @spec summarize_needs_evolution(map(), map()) :: String.t()
  def summarize_needs_evolution(original_needs, current_needs) do
    satisfaction = calculate_satisfaction_level(original_needs, current_needs)
    
    lines = [
      "=== Needs Evolution Summary ===",
      "Overall satisfaction: #{satisfaction}%",
      "",
      "Current Needs:",
      format_needs(current_needs),
      "",
      "Changes from Original:",
      format_need_changes(original_needs, current_needs)
    ]
    
    Enum.join(lines, "\n")
  end
  
  @doc false
  @spec format_needs(map()) :: String.t()
  defp format_needs(needs) do
    needs
      |> Enum.sort_by(fn {_domain, value} -> -value end)
      |> Enum.map_join("\n", fn {domain, value} ->
        bar = String.duplicate("█", round(value * 20))
        "  #{String.pad_trailing(to_string(domain), 15)} #{Float.round(value, 2)} #{bar}"
      end)
  end
  
  @doc false
  @spec format_need_changes(map(), map()) :: String.t()
  defp format_need_changes(original_needs, current_needs) do
    original_needs
      |> Enum.map(fn {domain, original_value} ->
        current_value = Map.get(current_needs, domain, original_value)
        change = current_value - original_value
        
        indicator = cond do
          change > 0.05 -> "↑ INCREASED"
          change < -0.05 -> "↓ DECREASED"
          true -> "→ STABLE"
        end
        
        "  #{String.pad_trailing(to_string(domain), 15)} #{Float.round(change, 2)} #{indicator}"
      end)
      |> Enum.join("\n")
  end
end
