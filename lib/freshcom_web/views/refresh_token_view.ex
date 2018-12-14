defmodule FreshcomWeb.RefreshTokenView do
  use FreshcomWeb, :view
  use JaSerializer.PhoenixView

  attributes [:prefixed_id]

  def type do
    "RefreshToken"
  end
end
