defmodule FreshcomWeb.RefreshTokenController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  # RetrieveRefreshToken
  def show(conn, _) do
    conn
    |> build_request(:show)
    |> Identity.get_refresh_token()
    |> send_response(conn, :show)
  end
end
