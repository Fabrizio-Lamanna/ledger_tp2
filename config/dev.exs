import Config

config :ledger, Ledger.Repo,
  database: "ledger_repo",
  username: "postgres",
  password: "postgres",
  hostname: "db",
  pool_size: 10
