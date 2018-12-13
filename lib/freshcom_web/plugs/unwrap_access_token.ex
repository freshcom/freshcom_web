defmodule FreshcomWeb.UnwrapAccessTokenPlug do
  require Logger
  import Plug.Conn
  alias FreshcomWeb.JWT

  def init(_), do: []

  def call(conn, _) do
    with [auth] <- get_req_header(conn, "authorization"),
         ["Bearer", access_token] <- String.split(auth),
         {:ok, access_token_payload} <- verify_access_token(access_token),
         {:ok, vas} <- extract_vas(access_token_payload)
    do
      Logger.info("VAS: #{inspect vas}")

      conn
      |> assign(:requester_id, vas[:requester_id])
      |> assign(:account_id, vas[:account_id])
      |> assign(:client_id, vas[:client_id])
    else
      _ ->
        conn
        |> assign(:requester_id, nil)
        |> assign(:account_id, nil)
        |> assign(:client_id, nil)
    end
  end

  def verify_access_token(access_token) do
    with {true, %{"cid" => _, "aid" => _, "exp" => exp} = fields} <- JWT.verify_token(access_token),
         true <- exp >= System.system_time(:second)
    do
      {:ok, fields}
    else
      {false, _} -> {:error, :invalid}
      false -> {:error, :invalid}
    end
  end

  def extract_vas(%{"rid" => rid, "aid" => aid, "cid" => cid, "typ" => "user"}) do
    {:ok, %{requester_id: rid, account_id: aid, client_id: cid}}
  end
  def extract_vas(%{"aid" => aid, "cid" => cid, "typ" => "publishable"}) do
    {:ok, %{requester_id: nil, account_id: aid, client_id: cid}}
  end
end
