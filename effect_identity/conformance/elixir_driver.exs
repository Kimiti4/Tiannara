alias TiannaraRuntime.Governance.EffectIdentity

# UAG-2F Elixir corpus driver: renders all 117 frozen vectors and emits the
# canonical cross-runtime line format:
#   <id>|<hash_a>|<hash_b>   both sides rendered
#   <id>|ERROR               at least one side failed to render
# Expectation semantics:
#   error    -> descriptor_a must render, descriptor_b must fail
#   same     -> both render with identical EffectID
#   different-> both render with different EffectIDs, or at least one side
#              fails to render (the pair cannot be equal)

fixture_path = Path.expand("../fixtures/effect_id_v1.json", __DIR__)

Application.ensure_all_started(:jason)
Application.ensure_all_started(:crypto)

{:ok, raw} = File.read(fixture_path)
%{"count" => 117, "vectors" => vectors, "expected_base_effect_id" => base} = Jason.decode!(raw)
117 = length(vectors)

render = fn desc ->
  case EffectIdentity.effect_id(desc) do
    {:ok, id} -> id
    {:error, _} -> nil
  end
end

[first | _] = vectors
^base = render.(first["descriptor_a"])

lines =
  Enum.map(vectors, fn v ->
    a = render.(v["descriptor_a"])
    b = render.(v["descriptor_b"])

    case v["expect"] do
      "error" ->
        if a == nil, do: raise("#{v["id"]}: error vector requires descriptor_a to render")
        if b != nil, do: raise("#{v["id"]}: error vector requires descriptor_b to fail")
        "#{v["id"]}|ERROR"

      "same" ->
        if a == nil or b == nil, do: raise("#{v["id"]}: same vector requires both sides to render")
        if a != b, do: raise("#{v["id"]}: expected same, got different")
        "#{v["id"]}|#{a}|#{b}"

      "different" ->
        cond do
          a == nil or b == nil -> "#{v["id"]}|ERROR"
          a == b -> raise("#{v["id"]}: expected different, got same")
          true -> "#{v["id"]}|#{a}|#{b}"
        end

      other ->
        raise("#{v["id"]}: unknown expectation #{inspect(other)}")
    end
  end)

IO.puts(Enum.join(lines, "\n"))
