defmodule FreshcomWeb.Controller do
  import Plug.Conn, only: [put_status: 2, send_resp: 3]
  import Phoenix.Controller, only: [render: 3]
  import FCSupport.Normalization, only: [normalize_by: 5]
  import FreshcomWeb.Normalization, only: [camelize_keys: 1, to_jsonapi_errors: 1]

  alias JaSerializer.Params
  alias Freshcom.{Request, Response, Filter}

  def build_request(conn, action, opts \\ [])

  def build_request(%{assigns: assigns, params: params}, :index, _) do
    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      search: params["search"],
      filter: params["filter"] || [],
      pagination: assigns[:pagination],
      include: params["include"],
      locale: params["locale"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :create, _) do
    fields =
      Params.to_attributes(params["data"] || %{})
      |> Map.drop(["type"])

    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      fields: fields,
      include: params["include"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :show, _) do
    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      identifiers: Map.take(params, ["id"]),
      include: params["include"],
      locale: params["locale"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :update, opts) do
    fields =
      Params.to_attributes(params["data"] || %{})
      |> Map.drop(["type"])

    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      identifiers: Map.take(params, opts[:identifiers] || ["id"]),
      fields: fields,
      include: params["include"],
      locale: params["locale"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :delete, opts) do
    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      identifiers: Map.take(params, opts[:identifiers] || ["id"])
    }
  end

  def normalize_request(req, :fields, key, func) do
    normalize_by(req, :fields, key, &is_binary/1, func)
  end

  def normalize_request(req, :filter, key, func) do
    %{req | filter: Filter.normalize(req.filter, key, func)}
  end

  def send_response({:ok, _}, conn, _, status: :no_content) do
    send_resp(conn, :no_content, "")
  end

  def send_response(other, _, _, _), do: other

  def send_response(%Response{data: data, meta: meta}, conn, :index) do
    conn
    |> put_status(:ok)
    |> render("index.json-api", data: data, opts: [meta: camelize_keys(meta), include: conn.query_params["include"]])
  end

  def send_response({:ok, %{data: data, meta: meta}}, conn, :create) do
    conn
    |> put_status(:created)
    |> render("show.json-api", data: data, opts: [meta: camelize_keys(meta), include: conn.query_params["include"]])
  end

  def send_response({:ok, %{data: data, meta: meta}}, conn, :show) do
    conn
    |> put_status(:ok)
    |> render("show.json-api", data: data, opts: [meta: camelize_keys(meta), include: conn.query_params["include"]])
  end

  def send_response({:ok, %{data: data, meta: meta}}, conn, :update) do
    conn
    |> put_status(:ok)
    |> render("show.json-api", data: data, opts: [meta: camelize_keys(meta), include: conn.query_params["include"]])
  end

  def send_response({:error, %{errors: errors}}, conn, _) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("errors.json-api", data: to_jsonapi_errors(errors))
  end

  def send_response(other, _, _), do: other
end