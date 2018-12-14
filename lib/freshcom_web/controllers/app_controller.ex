defmodule FreshcomWeb.AppController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller

  alias Freshcom.{Identity, Response}

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # ListApp
  def index(conn, _) do
    req = build_request(conn, :index)

    case Identity.list_app(req) do
      {:ok, resp} ->
        {:ok, %{data: total_count}} = Identity.count_app(req)
        {:ok, %{data: all_count}} = Identity.count_app(%{req | filter: [], search: nil})

        resp
        |> Response.put_meta(:total_count, total_count)
        |> Response.put_meta(:all_count, all_count)
        |> send_response(conn, :index)

      other ->
        send_response(other, conn, :index)
    end
  end

  # AddApp
  def create(conn, %{"data" => %{"type" => "App"}}) do
    conn
    |> build_request(:create)
    |> Identity.add_app()
    |> send_response(conn, :create)
  end

  # # RetrieveCurrentUser
  # def show(%{assigns: assigns} = conn, _) do
  #   conn
  #   |> build_request(:show)
  #   |> Request.put(:identifiers, "id", assigns[:requester_id])
  #   |> Identity.get_user()
  #   |> send_response(conn, :show)
  # end

  # # UpdateUser
  # def update(conn, _) do
  #   conn
  #   |> build_request(:update)
  #   |> Identity.update_user_info()
  #   |> send_response(conn, :show)
  # end

  # # DeleteUser
  # def delete(conn, _) do
  #   conn
  #   |> build_request(:delete, identifiers: ["id"])
  #   |> Identity.delete_user()
  #   |> send_response(conn, :delete, status: :no_content)
  # end
end
