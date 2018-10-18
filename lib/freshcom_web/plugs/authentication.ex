defmodule FreshcomWeb.AuthenticationPlug do
  require Logger
  import Plug.Conn
  alias FreshcomWeb.JWT

  def init(exception_paths), do: exception_paths

  def call(conn, exception_paths \\ []) do
    with [auth] <- get_req_header(conn, "authorization"),
         ["Bearer", access_token] <- String.split(auth),
         {:ok, access_token_payload} <- verify_access_token(access_token),
         {:ok, requester} <- extract_requester(access_token_payload)
    do
      Logger.info("Requester: #{inspect requester}")
      assign(conn, :requester, requester)
    else
      true -> conn
      _ ->
        if Enum.member?(exception_paths, conn.request_path) do
          assign(conn, :requester, %{id: nil, account_id: nil})
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

  def extract_requester(%{"prn" => user_id, "aud" => account_id, "typ" => "user"}) do
    {:ok, %{user_id: user_id, account_id: account_id}}
  end
  def extract_requester(%{"prn" => account_id, "typ" => "publishable"}) do
    {:ok, %{user_id: nil, account_id: account_id}}
  end
end
