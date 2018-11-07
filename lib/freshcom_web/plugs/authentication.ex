defmodule FreshcomWeb.AuthenticationPlug do
  require Logger
  import Plug.Conn
  alias FreshcomWeb.JWT

  def init(exception_paths), do: exception_paths

  def call(conn, exception_paths \\ []) do
    with [auth] <- get_req_header(conn, "authorization"),
         ["Bearer", access_token] <- String.split(auth),
         {:ok, access_token_payload} <- verify_access_token(access_token),
         {:ok, vas} <- extract_vas(access_token_payload)
    do
      Logger.info("VAS: #{inspect vas}")

      conn
      |> assign(:requester_id, vas[:requester_id])
      |> assign(:account_id, vas[:account_id])
    else
      true -> conn
      _ ->
        if Enum.member?(exception_paths, conn.request_path) do
          conn
          |> assign(:requester_id, nil)
          |> assign(:account_id, nil)
        else
          halt send_resp(conn, 401, "")
        end
    end
  end

  def verify_access_token(access_token) do
    with {true, %{ "prn" => _, "exp" => exp } = fields} <- JWT.verify_token(access_token),
         true <- exp >= System.system_time(:second)
    do
      {:ok, fields}
    else
      {false, _} -> {:error, :invalid}
      false -> {:error, :invalid}
    end
  end

  def extract_vas(%{"prn" => rid, "aud" => account_id, "typ" => "user"}) do
    {:ok, %{requester_id: rid, account_id: account_id}}
  end
  def extract_vas(%{"prn" => account_id, "typ" => "publishable"}) do
    {:ok, %{requester_id: nil, account_id: account_id}}
  end
end
