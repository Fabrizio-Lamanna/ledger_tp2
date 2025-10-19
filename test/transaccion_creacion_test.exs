defmodule Ledger.Transaccion.CreacionTest do
  use ExUnit.Case, async: true
  alias Ledger.{Transaccion, Moneda, User, Repo}
  alias Ledger.Transaccion.Creacion

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Repo.delete_all(Transaccion)
    Repo.delete_all(Moneda)
    Repo.delete_all(User)

    {:ok, _msg} = User.crear_usuario(n: "Lionel", b: "1990-01-01")
    {:ok, _msg} = User.crear_usuario(n: "Antonella", b: "1992-05-12")
    {:ok, _msg} = Moneda.crear_moneda(n: "USD", p: 1.0)
    {:ok, _msg} = Moneda.crear_moneda(n: "EUR", p: 1.1)

    moneda1 = Repo.get_by(Moneda, nombre: "USD")
    moneda2 = Repo.get_by(Moneda, nombre: "EUR")

    {:ok,
     usuario1: Repo.get_by(User, nombre: "Lionel"),
     usuario2: Repo.get_by(User, nombre: "Antonella"),
     moneda1: moneda1,
     moneda2: moneda2}
  end

  test "se crea una transaccion de alta de cuenta", %{usuario1: u, moneda1: m} do
    parametros = [u: u.id, m: m.nombre, a: 100.0]
    {:ok, msg} = Creacion.alta_cuenta(parametros)

    assert String.contains?(msg, "Transaccion alta_cuenta creada con id:")
    transaccion = Repo.one(Transaccion)
    assert transaccion.tipo == "alta_cuenta"
    assert transaccion.monto == 100.0
    assert transaccion.cuenta_origen_id == u.id
    assert transaccion.moneda_origen_id == m.id
  end

  test "se realiza una transferencia entre cuentas", %{usuario1: u1, usuario2: u2, moneda1: m} do
    Creacion.alta_cuenta(u: u1.id, m: m.nombre, a: 200.0)
    Creacion.alta_cuenta(u: u2.id, m: m.nombre, a: 50.0)

    parametros = [o: u1.id, d: u2.id, m: m.nombre, a: 75.0]
    {:ok, msg} = Creacion.realizar_transferencia(parametros)

    assert String.contains?(msg, "Transferencia creada con id:")
    transaccion = Repo.get_by(Transaccion, tipo: "transferencia")
    assert transaccion.cuenta_origen_id == u1.id
    assert transaccion.cuenta_destino_id == u2.id
    assert transaccion.monto == 75.0
    assert transaccion.moneda_origen_id == m.id
  end

  test "se realiza un swap de monedas", %{usuario1: u1, moneda1: m1, moneda2: m2} do
    Creacion.alta_cuenta(u: u1.id, m: m1.nombre, a: 150.0)
    Creacion.alta_cuenta(u: u1.id, m: m2.nombre, a: 100.0)

    parametros = [u: u1.id, mo: m1.nombre, md: m2.nombre, a: 50.0]
    {:ok, msg} = Creacion.realizar_swap(parametros)

    assert String.contains?(msg, "Swap creado con id:")
    transaccion = Repo.get_by(Transaccion, tipo: "swap")
    assert transaccion.cuenta_origen_id == u1.id
    assert transaccion.moneda_origen_id == m1.id
    assert transaccion.moneda_destino_id == m2.id
    assert transaccion.monto == 50.0
  end

  test "error dar de alta una cuenta que ya existe", %{usuario1: u, moneda1: m} do
    parametros = [u: u.id, m: m.nombre, a: 100.0]
    {:ok, _msg} = Creacion.alta_cuenta(parametros)
    {estado, comando, mensaje} = Creacion.alta_cuenta(parametros)

    {estado_esperado, comando_esperado, mensaje_esprado} =
      {:error, "alta_cuenta", "Cuenta ya existe"}

    assert {estado_esperado, comando_esperado, mensaje_esprado} == {estado, comando, mensaje}
  end

  test "error si no se especifica una moneda al hacer alta_cuenta", %{usuario1: u} do
    parametros = [u: u.id, m: nil, a: 100.0]
    {estado, comando, mensaje} = Creacion.alta_cuenta(parametros)

    {estado_esperado, comando_esperado, mensaje_esprado} =
      {:error, "alta_cuenta", "La moneda no fue especificada"}

    assert {estado_esperado, comando_esperado, mensaje_esprado} == {estado, comando, mensaje}
  end

  test "error si el monto no es numerico al hacer alta_cuenta", %{usuario1: u, moneda1: m} do
    parametros = [u: u.id, m: m.nombre, a: "monto_no_numerico"]
    {estado, comando, mensaje} = Creacion.alta_cuenta(parametros)

    {estado_esperado, comando_esperado, mensaje_esprado} =
      {:error, "alta_cuenta", "El monto debe ser un valor numerico"}

    assert {estado_esperado, comando_esperado, mensaje_esprado} == {estado, comando, mensaje}
  end

  test "error al realizar transaccion con cuenta inexistente", %{
    usuario1: u1,
    usuario2: u2,
    moneda1: m
  } do
    parametros = [o: u1.id, d: u2.id, m: m.nombre, a: 100]
    {estado, comando, mensaje} = Creacion.realizar_transferencia(parametros)

    {estado_esperado, comando_esperado, mensaje_esprado} =
      {:error, "realizar_transferencia",
       "La cuenta (usuario id: #{u1.id}, moneda: USD) no existe"}

    assert {estado_esperado, comando_esperado, mensaje_esprado} == {estado, comando, mensaje}
  end
end
