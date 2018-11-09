defmodule FreshcomWeb.Router do
  use FreshcomWeb, :router

  pipeline :api do
    plug :accepts, ["json-api"]
    plug FreshcomWeb.AuthenticationPlug, ["/v1/token", "/v1/users", "/v1/password_reset_tokens", "/v1/email_verifications", "/v1/password"]
    plug JaSerializer.Deserializer
  end

  scope "/v1/", FreshcomWeb do
    pipe_through :api

    options "/*path", WelcomeController, :options

    resources "/users", UserController, only: [:index, :create, :show, :update, :delete]
    post "/token", TokenController, :create
  end
end
