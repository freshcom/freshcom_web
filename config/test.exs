use Mix.Config

config :ex_unit, capture_log: true

config :argon2_elixir, t_cost: 1, m_cost: 8

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.get_env("EVENTSTORE_DB_USERNAME"),
  password: System.get_env("EVENTSTORE_DB_PASSWORD"),
  database: "fc_identity_eventstore_test",
  hostname: "localhost",
  pool_size: 10

# Print only warnings and errors during test
config :logger, level: :warn

config :fc_state_storage, adapter: FCStateStorage.MemoryAdapter

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :freshcom_web, FreshcomWeb.Endpoint,
  http: [port: 4001],
  server: false

config :freshcom, Freshcom.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "freshcom_projections_test",
  hostname: "localhost",
  username: System.get_env("PROJECTION_DB_USERNAME"),
  password: System.get_env("PROJECTION_DB_PASSWORD"),
  pool: Ecto.Adapters.SQL.Sandbox