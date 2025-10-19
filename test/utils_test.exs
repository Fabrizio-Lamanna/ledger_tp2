defmodule Ledger.UtilsTest do
  use ExUnit.Case
  alias Ledger.Utils
  import Ecto.Changeset

  test "transformar_errores_para_salida formatea correctamente los errores del changeset" do
    changeset =
      {%{}, %{nombre: :string}}
      |> cast(%{}, [:nombre])
      |> validate_required([:nombre])

    resultado = Utils.transformar_errores_para_salida(changeset)
    assert resultado == "can't be blank"
  end

  test "convertir_a_float convierte string con punto a float" do
    assert Utils.convertir_a_float("3.14") == 3.14
  end

  test "convertir_a_float convierte string sin punto a float agregando .0" do
    assert Utils.convertir_a_float("5") == 5.0
  end

  test "convertir_a_float no modifica un float" do
    assert Utils.convertir_a_float(7.2) == 7.2
  end

  test "convertir_a_float no modifica un integer" do
    assert Utils.convertir_a_float(10) == 10
  end

  test "calcular_equivalencia_entre_monedas retorna la cantidad correcta" do
    moneda_origen = %{precio: 2.0}
    moneda_destino = %{precio: 4.0}
    monto = 8.0

    # 8 * 2 = 16 USD, 16 / 4 = 4 unidades en moneda_destino
    resultado = Utils.calcular_equivalencia_entre_monedas(monto, moneda_origen, moneda_destino)
    assert resultado == 4.0
  end
end
