defmodule FreshcomWeb.AppView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :prefixed_id,
    :name
  ]

  def type do
    "App"
  end
end
