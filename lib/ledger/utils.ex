defmodule Ledger.Utils do
  def transformar_errores_para_salida(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.flat_map(fn {_campo, mensajes} -> mensajes end)
    |> Enum.join("; ")
  end

  def convertir_a_float(n) when is_binary(n) do
    if(String.contains?(n, "."), do: n, else: n <> ".0") |> String.to_float()
  end

  def convertir_a_float(n) do
    n
  end

  def calcular_equivalencia_entre_monedas(monto, moneda_origen, moneda_destino) do
    monto_equivalencia_en_usdt = monto * moneda_origen.precio
    monto_equivalencia_en_moneda_destino = monto_equivalencia_en_usdt / moneda_destino.precio
    monto_equivalencia_en_moneda_destino
  end
end
