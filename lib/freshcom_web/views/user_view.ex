defmodule FreshcomWeb.UserView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :name
  ]

  def type do
    "User"
  end
end
