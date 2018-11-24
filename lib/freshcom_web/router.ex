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
  end

  scope "/v1", FreshcomWeb do
    pipe_through [:plain, :authenticated, :jsonapi]

    options "/*path", WelcomeController, :options

    get "/account", AccountController, :show

    resources "/users", UserController, only: [:index, :show, :update, :delete]
    get "/user", UserController, :show
    patch "/user", UserController, :update
  end
end
