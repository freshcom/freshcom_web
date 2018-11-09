defmodule FreshcomWeb.UserController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _) do
    conn
    |> build_request(:index)
    |> Identity.list_user()
    |> send_response(conn, :index)
  end

  def create(%{assigns: %{account_id: nil}} = conn, %{"data" => %{"type" => "User"}}) do
    conn
    |> build_request(:create)
    |> Identity.register_user()
    |> send_response(conn, :create)
  end
end
