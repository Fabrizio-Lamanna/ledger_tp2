defmodule Ledger.TransaccionTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Ledger.{Repo, Transaccion}
  alias Ledger.Transaccion.Creacion

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    Repo.delete_all(Transaccion)
    Repo.delete_all(Ledger.User)
    Repo.delete_all(Ledger.Moneda)

    Repo.insert!(%Ledger.Moneda{id: 1, nombre: "USDT", precio: 1.0})
    Repo.insert!(%Ledger.Moneda{id: 2, nombre: "BTC", precio: 50000.0})

    Repo.insert!(%Ledger.User{id: 10, nombre: "Agustin", fecha_nacimiento: ~D[2002-02-15]})
    Repo.insert!(%Ledger.User{id: 11, nombre: "Juan", fecha_nacimiento: ~D[2001-05-20]})

    {:ok, _} = Creacion.alta_cuenta(u: 10, m: "USDT", a: 1000.0)
    {:ok, _} = Creacion.alta_cuenta(u: 10, m: "BTC", a: 1000.0)
    {:ok, _} = Creacion.alta_cuenta(u: 11, m: "USDT", a: 500.0)

    {:ok, _} = Creacion.realizar_transferencia(o: 10, d: 11, m: "USDT", a: 100)
    {:ok, _} = Creacion.realizar_swap(u: 10, mo: "USDT", md: "BTC", a: 50)

    :ok
  end

  test "muestra todas las transacciones de un usuario" do
    output =
      capture_io(fn ->
        {:ok, msg} = Transaccion.transacciones_de_cuenta(c1: 10, c2: nil)
        assert msg == "\nSe han mostrado todas las transacciones"
      end)

    assert output =~ "transferencia"
    assert output =~ "swap"
  end

  test "muestra transacciones filtradas entre dos usuarios" do
    output =
      capture_io(fn ->
        {:ok, msg} = Transaccion.transacciones_de_cuenta(c1: 10, c2: 11)
        assert msg == "\nSe han mostrado todas las transacciones"
      end)

    assert output =~ "transferencia"
    refute output =~ "swap"
  end

  test "devuelve error si faltan flags" do
    {:error, "transacciones", info} = Transaccion.transacciones_de_cuenta([])
    assert info == "Faltan las siguientes flags necesarias: c1"
  end

  test "marca como error si falta un campo requerido para alta_cuenta" do
    # falta monto
    attrs = %{cuenta_origen_id: 1, moneda_origen_id: 1, tipo: "alta_cuenta"}
    changeset = Transaccion.alta_cuenta_changeset(%Transaccion{}, attrs)
    refute changeset.valid?
    assert Enum.any?(changeset.errors, fn {field, _} -> field == :monto end)
  end

  test "marca como error si falta un campo requerido prara transferencia" do
    # falta cuenta_destino_id
    attrs = %{cuenta_origen_id: 1, moneda_origen_id: 1, monto: 50.0, tipo: "transferencia"}
    changeset = Transaccion.realizar_transferencia_changeset(%Transaccion{}, attrs)
    refute changeset.valid?
    assert Enum.any?(changeset.errors, fn {field, _} -> field == :cuenta_destino_id end)
  end

  test "marca como error si falta un campo requerido para swap" do
    # falta moneda_destino_id
    attrs = %{cuenta_origen_id: 1, moneda_origen_id: 1, monto: 30.0, tipo: "swap"}
    changeset = Transaccion.realizar_swap_changeset(%Transaccion{}, attrs)
    refute changeset.valid?
    assert Enum.any?(changeset.errors, fn {field, _} -> field == :moneda_destino_id end)
  end
end
