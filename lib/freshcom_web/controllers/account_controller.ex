defmodule FreshcomWeb.AccountController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # RetrieveCurrentAccount
  def show(conn, _) do
    conn
    |> build_request(:show)
    |> Identity.get_account()
    |> send_response(conn, :show)
  end
end
