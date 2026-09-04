defmodule Tiannara.CEL.Policy.RuntimePolicy do
  defstruct [
    :id,
    :name,
    :description,
    :type,
    :conditions,
    :actions,
    :priority,
    :enabled,
    :version,
    :created_by,
    :created_at,
    :expires_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t(),
          type: atom(),
          conditions: map(),
          actions: map(),
          priority: integer(),
          enabled: boolean(),
          version: String.t(),
          created_by: String.t(),
          created_at: DateTime.t(),
          expires_at: DateTime.t() | nil
        }

  def new(id, name, type, conditions, actions, opts \\ []) do
    %__MODULE__{
      id: id,
      name: name,
      description: Keyword.get(opts, :description, ""),
      type: type,
      conditions: conditions,
      actions: actions,
      priority: Keyword.get(opts, :priority, 100),
      enabled: Keyword.get(opts, :enabled, true),
      version: Keyword.get(opts, :version, "1.0.0"),
      created_by: Keyword.get(opts, :created_by, "system"),
      created_at: DateTime.utc_now(),
      expires_at: Keyword.get(opts, :expires_at)
    }
  end
end
