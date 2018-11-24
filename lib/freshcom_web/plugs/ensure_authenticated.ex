defmodule FreshcomWeb.EnsureAuthenticatedPlug do
  import Plug.Conn

  def init(_), do: []

  def call(%{assigns: assigns} = conn, _) do
    unless assigns[:account_id] do
      halt send_resp(conn, 401, "")
    else
      conn
    end
  end
end
