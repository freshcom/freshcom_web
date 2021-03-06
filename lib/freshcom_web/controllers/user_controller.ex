defmodule FreshcomWeb.UserController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Normalization, only: [underscore: 1]

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # ListUser
  def index(conn, _) do
    conn
    |> build_request(:index)
    |> normalize_request(:filter, "role", &underscore/1)
    |> list_and_count(&Identity.list_user/1, &Identity.count_user/1)
    |> send_response(conn, :index)
  end

  # RegisterUser
  def create(%{assigns: %{account_id: nil}} = conn, %{"data" => %{"type" => "User"}}) do
    conn
    |> build_request(:create)
    |> Identity.register_user()
    |> send_response(conn, :create)
  end

  # AddUser
  def create(conn, %{"data" => %{"type" => "User"}}) do
    conn
    |> build_request(:create)
    |> normalize_request(:data, "role", &underscore/1)
    |> Identity.add_user()
    |> send_response(conn, :create)
  end

  # RetrieveUser
  def show(conn, %{"id" => _}) do
    conn
    |> build_request(:show)
    |> Identity.get_user()
    |> send_response(conn, :show)
  end

  # RetrieveCurrentUser
  def show(%{assigns: assigns} = conn, _) do
    conn
    |> build_request(:show)
    |> Request.put(:identifier, "id", assigns[:requester_id])
    |> Identity.get_user()
    |> send_response(conn, :show)
  end

  # UpdateUser
  def update(conn, _) do
    conn
    |> build_request(:update)
    |> Identity.update_user_info()
    |> send_response(conn, :show)
  end

  def change_default_account(conn, _) do
    conn
    |> build_request(:update)
    |> Identity.change_default_account()
    |> send_response(conn, :show)
  end

  # ChangeUserRole
  def change_role(conn, _) do
    conn
    |> build_request(:update)
    |> normalize_request(:data, "value", &underscore/1)
    |> Identity.change_user_role()
    |> send_response(conn, :show)
  end

  # GeneratePasswordResetToken
  def generate_password_reset_token(%{assigns: assigns} = conn, _) do
    response =
      conn
      |> build_request(:update, identifier: ["id", "username"])
      |> Identity.generate_password_reset_token()

    if assigns[:requester_id] do
      send_response(response, conn, :create)
    else
      send_response(response, conn, :show, status: :no_content)
    end
  end

  # ChangePassword
  def change_password(conn, _) do
    conn
    |> build_request(:update, identifier: ["id", "reset_token"])
    |> Identity.change_password()
    |> send_response(conn, :show)
  end

  # DeleteUser
  def delete(conn, _) do
    conn
    |> build_request(:delete, identifier: ["id"])
    |> Identity.delete_user()
    |> send_response(conn, :delete, status: :no_content)
  end
end
