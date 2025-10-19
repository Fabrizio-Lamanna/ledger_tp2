defmodule Ledger.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :nombre, :string, null: false
      add :fecha_nacimiento, :date, null: false
      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
  end
end

end
