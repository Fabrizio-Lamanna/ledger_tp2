defmodule Ledger.Repo.Migrations.CrearMonedas do
  use Ecto.Migration

  def change do
    create table(:monedas) do
      add :nombre, :string, null: false
      add :precio, :float, null: false
      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
    end
  end
end
