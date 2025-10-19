defmodule Ledger.Transaccion.DeshacerTest do
  use ExUnit.Case, async: false
  alias Ledger.Repo
  alias Ledger.Transaccion.Deshacer
  alias Ledger.Transaccion.Creacion
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    Repo.delete_all(Ledger.Transaccion)
    Repo.delete_all(Ledger.User)
    Repo.delete_all(Ledger.Moneda)

    Repo.insert!(%Ledger.Moneda{id: 1, nombre: "USDT", precio: 1.0})
    Repo.insert!(%Ledger.Moneda{id: 2, nombre: "BTC", precio: 50000.0})

    Repo.insert!(%Ledger.User{id: 10, nombre: "Franco Mastantouno", fecha_nacimiento: ~D[2002-02-15]})
    Repo.insert!(%Ledger.User{id: 11, nombre: "Alejandro Garnacho", fecha_nacimiento: ~D[2001-05-20]})

    {:ok, _} = Creacion.alta_cuenta(u: 10, m: "USDT", a: 1000.0)
    {:ok, _} = Creacion.alta_cuenta(u: 10, m: "BTC", a: 1000.0)
    {:ok, _} = Creacion.alta_cuenta(u: 11, m: "USDT", a: 500.0)

    :ok
  end

  test "realizar y deshacer una transferencia" do
    {:ok, _msg} = Creacion.realizar_transferencia(o: 10, d: 11, m: "USDT", a: 100)

    transaccion =
      Repo.one!(
        from t in Ledger.Transaccion,
          where: t.cuenta_origen_id == 10 and t.tipo == "transferencia"
      )

    {:ok, msg} = Deshacer.deshacer_transaccion(id: transaccion.id)
    assert msg == "Transaccion deshecha correctamente"
  end

  test "realizar y deshacer un swap" do
    {:ok, _} = Creacion.realizar_swap(u: 10, mo: "USDT", md: "BTC", a: 50)

    transaccion =
      Repo.one!(
        from t in Ledger.Transaccion, where: t.cuenta_origen_id == 10 and t.tipo == "swap"
      )

    {:ok, msg} = Deshacer.deshacer_transaccion(id: transaccion.id)
    assert msg == "Transaccion deshecha correctamente"
  end

  test "no se puede deshacer un alta_cuenta" do
    {:ok, _msg} = Creacion.alta_cuenta(u: 11, m: "BTC", a: 100)

    transaccion =
      Repo.one!(
        from t in Ledger.Transaccion,
          where: t.cuenta_origen_id == 11 and t.tipo == "alta_cuenta",
          order_by: [desc: t.id],
          limit: 1
      )

    {:error, tipo, msg} = Deshacer.deshacer_transaccion(id: transaccion.id)

    assert tipo == "deshacer_transaccion"
    assert msg == "No se puede deshacer un alta de cuenta"
  end

  test "no se puede deshacer si hay transacciones mas recientes" do
    {:ok, _msg} = Creacion.realizar_transferencia(o: 10, d: 11, m: "USDT", a: 100)
    :timer.sleep(1000) # sin timer se crean con la misma fecha y no puede apreciar la diferencia de tiempo
    {:ok, _msg} = Creacion.realizar_swap(u: 10, mo: "USDT", md: "BTC", a: 10)

    transaccion =
      Repo.one!(
        from t in Ledger.Transaccion,
          where: t.cuenta_origen_id == 10 and t.tipo == "transferencia",
          limit: 1
      )

    {estado, comando, info} = Deshacer.deshacer_transaccion(id: transaccion.id)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "deshacer_transaccion", "Existen transacciones mas recientes para las cuentas involucradas"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end
end
