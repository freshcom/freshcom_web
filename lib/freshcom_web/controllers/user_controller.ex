defmodule FreshcomWeb.UserController do
  use FreshcomWeb, :controller

  alias JaSerializer.Params
  alias Freshcom.Identity
  alias FreshcomWeb.Normalization

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(%{assigns: %{requester: %{account_id: nil}}} = conn, %{"data" => %{"type" => "User"}} = params) do
    fields =
      params["data"]
      |> Params.to_attributes()

    response = Identity.register_user(%Request{
      requester: conn.assigns[:requester],
      fields: fields
    })

    case response do
      {:ok, %{data: user}} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: user)

      {:error, %{errors: errors}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("errors.json-api", data: Normalization.errors(errors))
    end
  end
end
