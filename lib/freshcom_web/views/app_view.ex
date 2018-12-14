defmodule FreshcomWeb.AppView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :prefixed_id,
    :name,
    :inserted_at
  ]

  def type do
    "App"
  end
end
