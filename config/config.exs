import Config

config :ledger, Ledger.Repo,
  database: "ledger_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false

config :ledger, ecto_repos: [Ledger.Repo]
