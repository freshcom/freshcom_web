defmodule FreshcomWeb.Controller do
  import Plug.Conn, only: [put_status: 2, send_resp: 3]
  import Phoenix.Controller, only: [render: 3]
  import FreshcomWeb.Normalization

  alias JaSerializer.Params
  alias Freshcom.Request

  def build_request(%{assigns: assigns, params: params}, :create) do
    %Request{
      requester_id: assigns[:requester_id],
      account_id: assigns[:account_id],
      fields: Params.to_attributes(params["data"]),
      include: params["include"]
    }
  end

  def send_response({:ok, _}, conn, _, status: :no_content) do
    send_resp(conn, :no_content, "")
  end

  def send_response({:ok, %{data: data, meta: meta}}, conn, :index) do
    conn
    |> put_status(:ok)
    |> render("index.json-api", data: data, opts: [meta: camelize_keys(meta), include: conn.query_params["include"]])
  end

  def send_response({:ok, %{data: data, meta: meta}}, conn, :create) do
    conn
    |> put_status(:created)
    |> render("show.json-api", data: data, opts: [meta: camelize_keys(meta), include: conn.query_params["include"]])
  end

  def send_response({:error, %{errors: errors}}, conn, _) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("errors.json-api", data: to_jsonapi_errors(errors))
  end

  def send_response(other, _, _), do: other
end