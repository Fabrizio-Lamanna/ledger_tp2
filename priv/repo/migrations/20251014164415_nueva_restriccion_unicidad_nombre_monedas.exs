defmodule Ledger.Repo.Migrations.NuevaRestriccionUnicidadNombreMonedas do
  use Ecto.Migration

  def change do
    create unique_index(:monedas, [:nombre])
  end
end
