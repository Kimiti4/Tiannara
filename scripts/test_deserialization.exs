# Test JSON deserialization WITH FIX
json_line = File.read!("data/repair_patterns.ndjson") |> String.split("\n", trim: true) |> hd()
json_map = Jason.decode!(json_line)

IO.puts("\n🔍 JSON Deserialization Test (WITH FIX)\n")
IO.inspect(Map.keys(json_map) |> Enum.take(15), label: "JSON Keys (first 15)")
IO.inspect(json_map["id"], label: "ID from JSON map")
IO.inspect(json_map["failure_signature"], label: "Signature from JSON map")

# Apply the fix: convert string keys to atom keys
struct_keys = Map.keys(%Tiannara.ASC.Crucible.RepairPattern{})
atom_key_map = 
  for {key, val} <- json_map,
      key in Enum.map(struct_keys, &Atom.to_string/1),
      into: %{} do
    {String.to_existing_atom(key), val}
  end

pattern = struct(Tiannara.ASC.Crucible.RepairPattern, atom_key_map)

IO.puts("\n🔍 After FIXED struct() conversion:\n")
IO.inspect(pattern.id, label: "Pattern ID")
IO.inspect(pattern.failure_signature, label: "Pattern Signature")
IO.inspect(pattern.failure_classification, label: "Pattern Classification")

if pattern.id != nil and pattern.failure_signature != nil do
  IO.puts("\n✅ FIX SUCCESSFUL - Fields properly deserialized!\n")
else
  IO.puts("\n❌ FIX FAILED - Fields still nil\n")
end
