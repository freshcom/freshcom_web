use Mix.Config

config :commanded,
  event_store_adapter: Commanded.EventStore.Adapters.EventStore,
  pubsub: [
    phoenix_pubsub: [
      adapter: Phoenix.PubSub.PG2,
      pool_size: 1
    ]
  ]

config :commanded_ecto_projections,
  repo: Freshcom.Repo

config :ex_aws, region: System.get_env("AWS_REGION")

config :ex_aws, :retries,
  max_attempts: 3,
  base_backoff_in_ms: 10,
  max_backoff_in_ms: 10_000

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :ja_serializer,
  key_format: {:custom, FreshcomWeb.Normalization, :camelize, :underscore}

config :phoenix, :format_encoders,
  "json-api": Poison

config :phoenix, FreshcomWeb.Endpoint,
  render_errors: [view: FreshcomWeb.ErrorView, accepts: ~w(html json json-api)]

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

config :fc_identity, :email_regex, ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

config :freshcom,
  ecto_repos: [Freshcom.Repo]

config :freshcom,
  pubsub: [
    adapter: Phoenix.PubSub.PG2,
    pool_size: 1,
    name: Freshcom.PubSubServer
  ]

config :freshcom_web, FreshcomWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "64CU1PkjCevE/bs5bYBJhr3w9FRnu+S5t1v7clGHubugExpdRU3zPTLoSIIRmm4v",
  render_errors: [view: FreshcomWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: FreshcomWeb.PubSub,
           adapter: Phoenix.PubSub.PG2]

import_config "#{Mix.env}.exs"
