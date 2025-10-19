defmodule Ledger.Repo.Migrations.UserNombreUnico do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:nombre])
  end
end
