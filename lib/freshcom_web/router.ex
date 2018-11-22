defmodule FreshcomWeb.Router do
  use FreshcomWeb, :router

  pipeline :jsonapi do
    plug :accepts, ["json-api"]
    plug FreshcomWeb.AuthenticationPlug, ["/v1/token", "/v1/users", "/v1/password_reset_tokens", "/v1/email_verifications", "/v1/password"]
    plug FreshcomWeb.PaginationPlug
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/v1/", FreshcomWeb do
    post "/token", TokenController, :create

    pipe_through :jsonapi

    options "/*path", WelcomeController, :options

    resources "/users", UserController, only: [:index, :create, :show, :update, :delete]
    get "/user", UserController, :show
    patch "/user", UserController, :update
  end
end
