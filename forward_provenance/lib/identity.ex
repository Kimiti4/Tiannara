defmodule TiannaraOS.Provenance.Identity do
  @moduledoc """
  Identity objects and uniqueness enforcement identity.

  Fixes failures: duplicate_execution_id, collision, identity-equality-becomes-
  metric-equality (test F). Identity is a hash over canonical bytes of the
  entity's defining fields, NOT over inline values that could coincide.
  """

  alias TiannaraOS.Provenance.Canon

  @spec object_id(binary(), map()) :: map()
  def object_id(kind, fields) when is_binary(kind) and is_map(fields) do
    body = %{"kind" => kind, "fields" => fields}
    %{"kind" => kind, "fields" => fields, "object_hash" => Canon.sha256(body)}
  end

  @doc """
  Uniqueness registry. Maintains a set of seen canonical hashes and ids.
  Returns `:ok` on first sighting, `{:error, :duplicate}` on repeat.
  """
  def new_registry, do: %{objects: MapSet.new(), ids: MapSet.new()}

  def register_object(reg, kind, fields) do
    id = object_id(kind, fields)
    h = Map.fetch!(id, "object_hash")

    if MapSet.member?(reg.objects, h) do
      {:error, :duplicate_object, id}
    else
      {:ok, id, %{reg | objects: MapSet.put(reg.objects, h)}}
    end
  end

  def register_id(reg, id) do
    if MapSet.member?(reg.ids, id) do
      {:error, :duplicate_id}
    else
      {:ok, %{reg | ids: MapSet.put(reg.ids, id)}}
    end
  end

  def uuid do
    # v4-style random UUID from :crypto strong bytes.
    <<u::binary-size(16)>> = :crypto.strong_rand_bytes(16)
    <<a::32, b::16, c::16, d::16, e::48>> = u
    # set version 4 and variant bits
    c = :erlang.bor(0x4000, :erlang.band(c, 0x0FFF))
    e = :erlang.bor(0x800000000000, :erlang.band(e, 0x3FFFFFFFFFFFF))
    :io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b", [a, b, c, d, e])
    |> IO.iodata_to_binary()
    |> String.downcase()
  end
end