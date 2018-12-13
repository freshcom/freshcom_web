defmodule FreshcomWeb.UserView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :type,
    :email,
    :username,
    :first_name,
    :last_name,
    :name,
    :role,
    :email_verified,
    :updated_at
  ]

  def type do
    "User"
  end

  def role(user) do
    camelize(user.role)
  end
end
