defmodule Rbac.User do
  alias Rbac.Schema.User

  def create(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Rbac.Repo.insert()
  end

  def get(id) do
    Rbac.Repo.get(User, id)
  end

  def get_by_email(email) do
    Rbac.Repo.get_by(User, email: email)
  end

  def list do
    Rbac.Repo.all(User)
  end

  def assign_role(user_id, role) do
    Rbac.Repo.insert(%Rbac.Schema.RoleAssignment{user_id: user_id, role: role})
  end
end
