defmodule FreshcomWeb.RefreshTokenController do
  use FreshcomWeb, :controller

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  # RetrieveRefreshToken
  def show(conn, _) do
    conn
    |> build_request(:show)
    |> Identity.get_api_key()
    |> send_response(conn, :show)
  end
end
