defmodule Tiannara.AAL.LexicalTensegrityField do
  @moduledoc """
  Deterministic lexical intent/domain routing.

  Domain vectors are sparse lexical features, not a general semantic model.
  Intent is returned as :unknown or :ambiguous unless exactly one supported
  action family is expressed in the request.
  """

  alias Tiannara.AAL.SemanticEncoder
  alias Tiannara.Math

  @threshold 0.65

  @domain_vectors %{
    engineering: SemanticEncoder.encode("hardware systems torsional rigidity schematics vhdl verilog"),
    medicine: SemanticEncoder.encode("proteomic decouplers mrna vaccine monoclonal antibody"),
    computation: SemanticEncoder.encode("polymorphic ast compilers bytecodes silicon topology"),
    materials: SemanticEncoder.encode("metallurgy nanotech crystalline grain boundaries tensile"),
    energy: SemanticEncoder.encode("quantum well capacitance atomic-layer energy cell storage"),
    cybernetics: SemanticEncoder.encode("homeostatic feedback controllers resonant frequencies"),
    architecture: SemanticEncoder.encode("autopoietic structural topologies self-healing grids")
  }

  @action_terms %{
    creation: ~w(create build generate implement write construct),
    analysis: ~w(analyze analyse inspect investigate diagnose explain understand),
    comparison: ~w(compare contrast differentiate versus),
    optimization: ~w(optimize optimise improve minimize minimise maximize maximise),
    execution: ~w(run execute launch start stop restart deploy),
    simulation: ~w(simulate model forecast predict)
  }

  @spec map_intent_vectors(String.t()) :: {atom(), [atom()]}
  def map_intent_vectors(raw_text) when is_binary(raw_text) do
    input_vector = SemanticEncoder.encode(raw_text)

    engaged_domains =
      @domain_vectors
      |> Enum.filter(fn {_domain, domain_vector} ->
        Math.cosine_similarity(input_vector, domain_vector) > @threshold
      end)
      |> Enum.map(fn {domain, _vector} -> domain end)

    {determine_core_action(raw_text), engaged_domains}
  end

  def map_intent_vectors(_), do: {:unknown, []}

  defp determine_core_action(raw_text) do
    normalized = raw_text |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, " ")
    words = MapSet.new(String.split(normalized, " ", trim: true))

    matches =
      Enum.filter(@action_terms, fn {_intent, terms} ->
        Enum.any?(terms, &MapSet.member?(words, &1))
      end)
      |> Enum.map(&elem(&1, 0))

    case matches do
      [intent] -> intent
      [] -> :unknown
      _ -> :ambiguous
    end
  end
end
