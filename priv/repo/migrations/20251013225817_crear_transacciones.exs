defmodule Ledger.Repo.Migrations.CrearTransacciones do
  use Ecto.Migration

  def change do
    create table(:transacciones) do
      add :moneda_origen_id, references(:monedas), null: false
      add :moneda_destino_id, references(:monedas), null: false
      add :monto, :float, null: false
      add :cuenta_origen_id, references(:users), null: false
      add :cuenta_destino_id, references(:users), null: false
      add :tipo, :string, null: false

      timestamps(inserted_at: :fecha_realizacion, updated_at: false)
    end
  end


end
