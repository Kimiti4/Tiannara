defmodule TiannaraOS.Provenance.Contract do
  @moduledoc """
  Contract identity: immutable contract hash over the full contract YAML/NML
  bytes plus the parameter set, plus an explicit contract_version.

  This fixes `contract_hash: null` everywhere in T0's contracts (none bound to
  any execution or certificate).
  """

  alias TiannaraOS.Provenance.Identity

  def build(opts) do
    contract_bytes = Keyword.fetch!(opts, :contract_bytes)
    contract_version = Keyword.fetch!(opts, :contract_version)
    parameter_set = Keyword.get(opts, :parameter_set, %{})
    schema_name = Keyword.get(opts, :schema_name, "tia-fp-contract-v1")

    # Name of canonical serialization spec used for identity computation.
    # Same spec name is self-describing: the contract carries its contract_hash
    # computed under this spec so the contract is verifiable with only the bytes.
    body = %{
      "contract_bytes" => contract_bytes,
      "contract_version" => contract_version,
      "parameter_set" => parameter_set,
      "schema_name" => schema_name
    }

    Identity.object_id("contract", body)
  end
end