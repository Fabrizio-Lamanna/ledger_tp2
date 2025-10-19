defmodule Ledger.Repo.Migrations.NoBorrarUsuariosYMonedasConReferencias do
  use Ecto.Migration

 def change do
    execute "ALTER TABLE transacciones DROP CONSTRAINT IF EXISTS transacciones_cuenta_origen_id_fkey"
    execute "ALTER TABLE transacciones DROP CONSTRAINT IF EXISTS transacciones_cuenta_destino_id_fkey"
    execute "ALTER TABLE transacciones DROP CONSTRAINT IF EXISTS transacciones_moneda_origen_id_fkey"
    execute "ALTER TABLE transacciones DROP CONSTRAINT IF EXISTS transacciones_moneda_destino_id_fkey"

    alter table(:transacciones) do
      modify :cuenta_origen_id, references(:users, on_delete: :restrict), null: false
      modify :cuenta_destino_id, references(:users, on_delete: :restrict), null: true
      modify :moneda_origen_id, references(:monedas, on_delete: :restrict), null: false
      modify :moneda_destino_id, references(:monedas, on_delete: :restrict), null: true
    end
  end
end
