defmodule FreshcomWeb.UserView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  alias Freshcom.User

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
    :password_reset_token,
    :password_reset_token_expires_at,
    :updated_at
  ]

  def type do
    "User"
  end

  def role(user) do
    camelize(user.role)
  end

  def password_reset_token(user) do
    if User.password_reset_token_expired?(user) do
      nil
    else
      user.password_reset_token
    end
  end

  def password_reset_token_expires_at(user) do
    if User.password_reset_token_expired?(user) do
      nil
    else
      user.password_reset_token_expires_at
    end
  end
end
