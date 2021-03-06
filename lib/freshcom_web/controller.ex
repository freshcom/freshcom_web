defmodule FreshcomWeb.Controller do
  import Plug.Conn, only: [put_status: 2, send_resp: 3]
  import Phoenix.Controller, only: [render: 3]
  import FCSupport.Normalization, only: [normalize_by: 5]
  import FreshcomWeb.Normalization

  alias JaSerializer.Params
  alias Freshcom.{Request, Response, Filter}

  def build_request(conn, action, opts \\ [])

  def build_request(%{assigns: assigns, params: params}, :index, _) do
    filter =
      Jason.decode!(params["filter"] || "[]")
      |> underscore_keys()

    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      search: params["search"],
      filter: filter,
      pagination: assigns[:pagination],
      include: params["include"],
      locale: params["locale"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :create, _) do
    data =
      Params.to_attributes(params["data"] || %{})
      |> Map.drop(["type"])

    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      data: data,
      include: params["include"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :show, _) do
    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      identifier: Map.take(params, ["id"]),
      include: params["include"],
      locale: params["locale"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :update, opts) do
    data =
      Params.to_attributes(params["data"] || %{})
      |> Map.drop(["type"])

    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      identifier: Map.take(params, opts[:identifier] || ["id"]),
      data: data,
      include: params["include"],
      locale: params["locale"]
    }
  end

  def build_request(%{assigns: assigns, params: params}, :delete, opts) do
    %Request{
      requester_id: assigns[:requester_id],
      client_id: assigns[:client_id],
      account_id: assigns[:account_id],
      identifier: Map.take(params, opts[:identifier] || ["id"])
    }
  end

  def normalize_request(req, :data, key, func) do
    normalize_by(req, :data, key, &is_binary/1, func)
  end

  def normalize_request(req, :filter, key, func) do
    %{req | filter: Filter.normalize(req.filter, key, func)}
  end

  def send_response({:ok, _}, conn, _, status: :no_content) do
    send_resp(conn, :no_content, "")
  end

  def send_response({:ok, _}, conn, _, status: :accepted) do
    send_resp(conn, :accepted, "")
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

  def list_and_count(req, list_func, count_func) do
    case list_func.(req) do
      {:ok, resp} ->
        {:ok, %{data: total_count}} = count_func.(req)
        {:ok, %{data: all_count}} = count_func.(%{req | filter: [], search: nil})

        resp
        |> Response.put_meta(:total_count, total_count)
        |> Response.put_meta(:all_count, all_count)

      other ->
        other
    end
  end
end