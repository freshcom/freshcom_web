defmodule FreshcomWeb.AppController do
  use FreshcomWeb, :controller

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # ListApp
  def index(conn, _) do
    conn
    |> build_request(:index)
    |> list_and_count(&Identity.list_app/1, &Identity.count_app/1)
    |> send_response(conn, :index)
  end

  # AddApp
  def create(conn, %{"data" => %{"type" => "App"}}) do
    conn
    |> build_request(:create)
    |> Identity.add_app()
    |> send_response(conn, :create)
  end

  # UpdateApp
  def update(conn, _) do
    conn
    |> build_request(:update)
    |> Identity.update_app()
    |> send_response(conn, :show)
  end

  # DeleteApp
  def delete(conn, _) do
    conn
    |> build_request(:delete, identifier: ["id"])
    |> Identity.delete_app()
    |> send_response(conn, :delete, status: :no_content)
  end
end
