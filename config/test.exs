import Config

config :ledger, Ledger.Repo,
  database: "ledger_repo_test",
  username: "postgres",
  password: "postgres",
  hostname: "db",
  pool: Ecto.Adapters.SQL.Sandbox
