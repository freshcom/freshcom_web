defmodule FreshcomWeb.UserController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller

  alias JaSerializer.Params
  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{assigns: assigns} = conn, params) do
    req = %Request{
      requester_id: assigns[:requester_id],
      account_id: assigns[:account_id],
      search: params["search"],
      filter: params["filter"],
      pagination: assigns[:pagination],
      include: params["include"],
      locale: params["locale"]
    }

    Identity.list_user(req)
    |> send_response(conn, :index)
  end

  def create(%{assigns: %{account_id: nil}} = conn, %{"data" => %{"type" => "User"}}) do
    conn
    |> build_request(:create)
    |> Identity.register_user()
    |> send_response(conn, :create)
  end
end
