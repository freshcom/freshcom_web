defmodule FreshcomWeb.Router do
  use FreshcomWeb, :router

  pipeline :plain do
    plug FreshcomWeb.CORSPlug
    plug FreshcomWeb.UnwrapAccessTokenPlug
  end

  pipeline :authenticated do
    plug FreshcomWeb.EnsureAuthenticatedPlug
  end

  pipeline :jsonapi do
    plug :accepts, ["json-api"]
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

    post "/users", UserController, :create
    put "/password", UserController, :change_password
    post "/password_reset_tokens", UserController, :generate_password_reset_token
  end

  scope "/v1", FreshcomWeb do
    pipe_through [:plain, :authenticated, :jsonapi]

    options "/*path", WelcomeController, :options

    # Identity
    get "/account", AccountController, :show
    patch "/account", AccountController, :update
    resources "/accounts", AccountController, only: [:create, :index, :delete]

    resources "/users", UserController, only: [:index, :show, :update, :delete]
    get "/user", UserController, :show
    patch "/user/relationships/default_account", UserController, :change_default_account
    put "/users/:id/role", UserController, :change_role

    get "/refresh_token", RefreshTokenController, :show

    resources "/apps", AppController, only: [:create, :index, :show, :update, :delete]
  end
end
