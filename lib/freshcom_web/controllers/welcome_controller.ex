defmodule FreshcomWeb.WelcomeController do
  use FreshcomWeb, :controller

  def index(conn, _params) do
    text conn, "Welcome"
  end

  def options(conn, _params) do
    text conn, ""
  end
end
