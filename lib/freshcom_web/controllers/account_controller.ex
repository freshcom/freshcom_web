defmodule FreshcomWeb.AccountController do
  use FreshcomWeb, :controller

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # ListAccount
  def index(conn, _) do
    conn
    |> build_request(:index)
    |> list_and_count(&Identity.list_account/1, &Identity.count_account/1)
    |> send_response(conn, :index)
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
    |> build_request(:delete, identifier: ["id"])
    |> Identity.close_account()
    |> send_response(conn, :delete, status: :accepted)
  end
end
