import Config

config :ledger, Ledger.Repo,
  database: "ledger_repo",
  username: "postgres",
  password: "postgres",
  hostname: "db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :ledger, ecto_repos: [Ledger.Repo]
