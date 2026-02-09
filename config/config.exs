import Config

config :ledger, ecto_repos: [Ledger.Repo]

config :ledger, Ledger.Repo,
  log: false

import_config "#{config_env()}.exs"
