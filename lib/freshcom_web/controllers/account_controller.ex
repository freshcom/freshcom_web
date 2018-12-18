defmodule FreshcomWeb.AccountController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller

  alias Freshcom.{Identity, Response}

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # ListUser
  def index(conn, _) do
    req = build_request(conn, :index)

    case Identity.list_account(req) do
      {:ok, resp} ->
        {:ok, %{data: total_count}} = Identity.count_account(req)
        {:ok, %{data: all_count}} = Identity.count_account(%{req | filter: [], search: nil})

        resp
        |> Response.put_meta(:total_count, total_count)
        |> Response.put_meta(:all_count, all_count)
        |> send_response(conn, :index)

      other ->
        send_response(other, conn, :index)
    end
  end

  # CreateAccount
  def create(conn, %{"data" => %{"type" => "Account"}}) do
    conn
    |> build_request(:create)
    |> Identity.create_account()
    |> send_response(conn, :create)
  end

  # RetrieveCurrentAccount
  def show(conn, _) do
    conn
    |> build_request(:show)
    |> Identity.get_account()
    |> send_response(conn, :show)
  end

  # UpdateCurrentAccount
  def update(conn, _) do
    conn
    |> build_request(:update)
    |> Identity.update_account_info()
    |> send_response(conn, :show)
  end

  # CloseAccount
  def delete(conn, _) do
    conn
    |> build_request(:delete, identifiers: ["id"])
    |> Identity.close_account()
    |> send_response(conn, :delete, status: :accepted)
  end
end
