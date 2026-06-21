defmodule Tiannara.Domains.TransferMatrix do
  @moduledoc """
  Tracks transfer events where discoveries are applied from a source domain to a target domain.
  Data is saved in `data/transfer_matrix.ndjson`.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :source_domain,     # atom/string (e.g. :engineering)
    :target_domain,     # atom/string (e.g. :robotics)
    :discovery_id,      # string/atom
    :transfer_success,  # float (0.0 to 1.0)
    :timestamp
  ]

  @file_path "data/transfer_matrix.ndjson"

  @doc """
  Loads all transfer matrix entries from persistence.
  """
  def all do
    if File.exists?(@file_path) do
      @file_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line ->
        case Jason.decode(line, keys: :atoms) do
          {:ok, attrs} -> 
            attrs = 
              attrs
              |> Map.update!(:source_domain, &String.to_atom(to_string(&1)))
              |> Map.update!(:target_domain, &String.to_atom(to_string(&1)))
            struct(__MODULE__, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      list = seeds()
      write_all(list)
      list
    end
  end

  @doc """
  Saves a single transfer matrix entry.
  """
  def save(%__MODULE__{} = entry) do
    list = all()
    entry = %{entry | timestamp: entry.timestamp || DateTime.utc_now() |> DateTime.to_iso8601()}
    
    new_list = 
      if Enum.any?(list, & &1.id == entry.id) do
        Enum.map(list, fn e -> if e.id == entry.id, do: entry, else: e end)
      else
        list ++ [entry]
      end

    write_all(new_list)
    {:ok, entry}
  end

  @doc """
  Saves all entries to file.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn entry -> Jason.encode!(entry) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  @doc """
  Default seeds for the cross-domain transfers.
  """
  def seeds do
    [
      %__MODULE__{
        id: "trans1",
        source_domain: :engineering,
        target_domain: :robotics,
        discovery_id: "structured_forgetting",
        transfer_success: 0.85
      },
      %__MODULE__{
        id: "trans2",
        source_domain: :cognition,
        target_domain: :governance,
        discovery_id: "identity_sustained_regeneration",
        transfer_success: 0.75
      },
      %__MODULE__{
        id: "trans3",
        source_domain: :ecology,
        target_domain: :economics,
        discovery_id: "scp_retention_boundary",
        transfer_success: 0.80
      },
      %__MODULE__{
        id: "trans4",
        source_domain: :computation,
        target_domain: :engineering,
        discovery_id: "generative_orbit_equivalence",
        transfer_success: 0.90
      }
    ]
  end
end
