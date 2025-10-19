defmodule Ledger.Repo.Migrations.CuentaYMonedaDestinoNoObligatorios do
  use Ecto.Migration

  def change do
    alter table(:transacciones) do
      modify :moneda_destino_id, :integer, null: true
      modify :cuenta_destino_id, :integer, null: true
    end
  end
end
