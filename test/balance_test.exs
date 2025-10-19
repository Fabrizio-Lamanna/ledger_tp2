defmodule Ledger.BalanceTest do
  use ExUnit.Case, async: false
  import Ecto.Query
  alias Ledger.{Repo, User, Moneda, Transaccion, Balance}
  alias Ledger.Transaccion.Creacion

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    Repo.delete_all(Transaccion)
    Repo.delete_all(User)
    Repo.delete_all(Moneda)

    usdt = Repo.insert!(%Moneda{id: 1, nombre: "USDT", precio: 1.0})
    btc = Repo.insert!(%Moneda{id: 2, nombre: "BTC", precio: 50000.0})

    user1 = Repo.insert!(%User{id: 10, nombre: "Agustin", fecha_nacimiento: ~D[2002-02-15]})
    user2 = Repo.insert!(%User{id: 11, nombre: "Juan", fecha_nacimiento: ~D[2001-05-20]})

    {:ok, _} = Creacion.alta_cuenta(u: user1.id, m: "USDT", a: 1000.0)
    {:ok, _} = Creacion.alta_cuenta(u: user1.id, m: "BTC", a: 2.0)
    {:ok, _} = Creacion.alta_cuenta(u: user2.id, m: "USDT", a: 500.0)

    {:ok, %{user1: user1, user2: user2, usdt: usdt, btc: btc}}
  end

  test "crear_balance_inicial devuelve mapa con todas las monedas en 0", %{usdt: usdt, btc: btc} do
    balance = Balance.crear_balance_inicial()
    assert balance[usdt.id] == 0.0
    assert balance[btc.id] == 0.0
  end

  test "modificar_balance suma correctamente para alta_cuenta", %{user1: user1, usdt: usdt} do
    trans =
      Repo.all(
        from t in Transaccion, where: t.cuenta_origen_id == ^user1.id and t.tipo == "alta_cuenta"
      )
      |> hd()

    trans =
      Repo.preload(trans, [:moneda_origen, :moneda_destino, :cuenta_origen, :cuenta_destino])

    balance = Balance.crear_balance_inicial()
    nuevo_balance = Balance.modificar_balance(balance, trans, Integer.to_string(user1.id))

    assert nuevo_balance[usdt.id] == trans.monto
  end

  test "modificar_balance resta y suma correctamente para transferencia", %{
    user1: user1,
    user2: user2,
    usdt: usdt
  } do
    {:ok, _} = Creacion.realizar_transferencia(o: user1.id, d: user2.id, m: "USDT", a: 200)
    trans = Repo.all(from t in Transaccion, where: t.tipo == "transferencia") |> hd()

    trans =
      Repo.preload(trans, [:moneda_origen, :moneda_destino, :cuenta_origen, :cuenta_destino])

    balance = Balance.crear_balance_inicial()
    balance1 = Balance.modificar_balance(balance, trans, Integer.to_string(user1.id))
    balance2 = Balance.modificar_balance(balance, trans, Integer.to_string(user2.id))

    assert balance1[usdt.id] == -200
    assert balance2[usdt.id] == 200
  end

  test "balance_de_cuenta muestra balance correctamente", %{user1: user1} do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        {:ok, msg} = Balance.balance_de_cuenta(c1: user1.id)
        assert msg =~ "Balance mostrado"
      end)

    assert output =~ "1="
    assert output =~ "2="
  end

  test "balance_de_cuenta devuelve error si faltan flags" do
    {:error, "balance", info} = Balance.balance_de_cuenta([])
    assert info == "Faltan las siguientes flags necesarias: c1"
  end

  test "se normaliza correctamente un balance" do
    balance = %{1 => 100, 2 => 1}
    monto_esperado = 50100.0
    {:ok, balance_normalizado} = Balance.normalizar_balance_a_moneda(balance, "USDT")

    assert balance_normalizado == monto_esperado
  end
end
