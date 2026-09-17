defmodule Rbac.Schema.AuditEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "audit_entries" do
    field(:action, :string)
    field(:operator_id, :binary_id)
    field(:resource, :string)
    field(:details, :map)
    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:action, :operator_id, :resource, :details])
    |> validate_required([:action, :operator_id, :resource])
  end
end
