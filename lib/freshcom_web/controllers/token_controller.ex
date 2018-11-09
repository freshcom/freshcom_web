defmodule FreshcomWeb.TokenController do
  use FreshcomWeb, :controller

  alias FreshcomWeb.Authentication

  action_fallback FreshcomWeb.FallbackController

  def create(conn, params) do
    case Authentication.create_access_token(params) do
      {:ok, token} ->
        conn
        |> put_status(:ok)
        |> json(token)

      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> json(errors)

      other -> other
    end
  end
end
