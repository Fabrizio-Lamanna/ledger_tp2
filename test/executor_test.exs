defmodule Ledger.ExecutorTest do
  use ExUnit.Case, async: false
  alias Ledger.Executor
  alias Ledger.Repo
  alias Ledger.Moneda
  alias Ledger.User
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    Repo.delete_all(Ledger.Transaccion)
    Repo.delete_all(User)
    Repo.delete_all(Moneda)

    Repo.insert!(%Moneda{id: 1, nombre: "USDT", precio: 1.0})
    Repo.insert!(%Moneda{id: 2, nombre: "BTC", precio: 50000.0})

    Repo.insert!(%User{id: 10, nombre: "Agustin", fecha_nacimiento: ~D[2002-02-15]})
    Repo.insert!(%User{id: 11, nombre: "Juan", fecha_nacimiento: ~D[2001-05-20]})

    :ok
  end

  test "crear usuario vía Executor" do
    {:ok, msg} = Executor.ejecutar_comando("crear_usuario", n: "Lautaro", b: "2000-01-01")
    assert msg =~ "Usuario creado"
  end

  test "crear moneda vía Executor" do
    {:ok, msg} = Executor.ejecutar_comando("crear_moneda", n: "ETH", p: 2000.0)
    assert msg =~ "Moneda creada"
  end

  test "alta de cuenta vía Executor" do
    {:ok, msg} = Executor.ejecutar_comando("alta_cuenta", u: 10, m: "USDT", a: 1000.0)
    assert msg =~ "Transaccion alta_cuenta creada"
  end

  test "realizar y deshacer transferencia vía Executor" do
    {:ok, _} = Executor.ejecutar_comando("alta_cuenta", u: 10, m: "USDT", a: 1000.0)
    {:ok, _} = Executor.ejecutar_comando("alta_cuenta", u: 11, m: "USDT", a: 500.0)

    {:ok, _} =
      Executor.ejecutar_comando("realizar_transferencia", o: 10, d: 11, m: "USDT", a: 100)

    transaccion =
      Repo.one!(
        from t in Ledger.Transaccion,
          where: t.cuenta_origen_id == 10 and t.tipo == "transferencia"
      )

    {:ok, msg} = Executor.ejecutar_comando("deshacer_transaccion", id: transaccion.id)
    assert msg == "Transaccion deshecha correctamente"
  end

  test "comando desconocido" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Executor.ejecutar_comando("no_existe", [])
      end)

    assert output =~ "Comando desconocido"
  end
end
