# Test nested classification deserialization
json_line = File.read!("data/repair_patterns.ndjson") |> String.split("\n", trim: true) |> hd()
json_map = Jason.decode!(json_line)

IO.puts("\n🔍 Testing Nested Classification Deserialization\n")

# Apply the fix with nested map conversion
struct_keys = Map.keys(%Tiannara.ASC.Crucible.RepairPattern{})

atom_key_map = 
  for {key, val} <- json_map,
      key in Enum.map(struct_keys, &Atom.to_string/1),
      into: %{} do
    atom_key = String.to_existing_atom(key)
    
    # Convert nested map keys to atoms if needed
    converted_val = 
      case val do
        %{} = nested_map when atom_key == :failure_classification ->
          for {nk, nv} <- nested_map, into: %{} do
            {String.to_existing_atom(nk), nv}
          end
        _ ->
          val
      end
    
    {atom_key, converted_val}
  end

pattern = struct(Tiannara.ASC.Crucible.RepairPattern, atom_key_map)

IO.puts("Pattern ID: #{inspect(pattern.id)}")
IO.puts("Pattern Signature: #{inspect(pattern.failure_signature)}")
IO.puts("Pattern Classification: #{inspect(pattern.failure_classification)}")

# Test similarity check
if pattern.failure_classification != nil do
  IO.puts("\n✅ Classification properly deserialized!")
  
  # Create a new classification to test similarity
  new_classification = %{
    domain: :implementation,
    category: :boundary,
    subcategory: :boundary_value,
    confidence: 0.9,
    keywords: ["test"],
    signature: "implementation:boundary:boundary_value"
  }
  
  result = Tiannara.ASC.Crucible.FailureClassifier.similarity_check(
    new_classification,
    pattern.failure_classification
  )
  
  IO.puts("Similarity check result: #{inspect(result)}")
  
  case result do
    {:match, level} ->
      IO.puts("✅ Similarity check SUCCESSFUL - Match level: #{level}")
    :no_match ->
      IO.puts("⚠️  No match (but no crash)")
  end
else
  IO.puts("\n❌ Classification is still nil!")
end

IO.puts("\n✅ Test complete\n")
