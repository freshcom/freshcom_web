defmodule FreshcomWeb.Router do
  use FreshcomWeb, :router

  pipeline :plain do
    plug FreshcomWeb.CORSPlug
  end

  pipeline :jsonapi do
    plug FreshcomWeb.AuthenticationPlug, ["/v1/token", "/v1/users", "/v1/password_reset_tokens", "/v1/email_verifications", "/v1/password"]
    plug FreshcomWeb.PaginationPlug
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/v1", FreshcomWeb do
    pipe_through :plain
    post "/token", TokenController, :create
  end

  scope "/v1", FreshcomWeb do
    pipe_through [:plain, :jsonapi]

    options "/*path", WelcomeController, :options

    get "/account", AccountController, :show

    resources "/users", UserController, only: [:index, :create, :show, :update, :delete]
    get "/user", UserController, :show
    patch "/user", UserController, :update
  end
end
