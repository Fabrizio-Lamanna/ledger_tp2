defmodule Ledger.MonedaTest do
  use ExUnit.Case, async: true
  alias Ledger.{Moneda, Repo, User, Transaccion}
  import ExUnit.CaptureIO

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Repo.delete_all(Ledger.Transaccion)
    Repo.delete_all(Moneda)
    :ok
  end

  test "se crea moneda correctamente" do
    parametros = [n: "BTC", p: 50000.0]
    {:ok, msg} = Moneda.crear_moneda(parametros)
    assert String.contains?(msg, "Moneda creada con id:")

    monedas = Repo.all(Moneda)
    assert length(monedas) == 1
    assert hd(monedas).nombre == "BTC"
    assert hd(monedas).precio == 50000.0
  end

  test "se edita una moneda correctamente" do
    parametros_creacion = [n: "BTC", p: 50000.0]
    {:ok, _msg} = Moneda.crear_moneda(parametros_creacion)

    moneda = Repo.get_by(Moneda, nombre: "BTC")
    id = moneda.id

    parametros_edicion = [id: id, p: 55000.0]
    {:ok, msg} = Moneda.editar_moneda(parametros_edicion)

    moneda_actualizada = Repo.get(Moneda, id)
    assert "Moneda actualizada correctamente: BTC" == msg
    assert moneda_actualizada.precio == 55000.0
  end

  test "se borra correctamente una moneda" do
    parametros_creacion = [n: "BTC", p: 50000.0]
    {:ok, _msg} = Moneda.crear_moneda(parametros_creacion)

    moneda = Repo.get_by(Moneda, nombre: "BTC")
    id = moneda.id

    parametros_borrar = [id: id]
    {:ok, msg} = Moneda.borrar_moneda(parametros_borrar)
    assert "Moneda borrada correctamente" == msg

    assert Repo.get(Moneda, id) == nil
  end

  test "se muestra correctamente una moneda" do
    parametros_creacion = [n: "BTC", p: 50000.0]
    {:ok, _msg} = Moneda.crear_moneda(parametros_creacion)

    moneda = Repo.get_by(Moneda, nombre: "BTC")
    id = moneda.id

    parametros_ver = [id: id]

    _output =
      capture_io(fn ->
        {:ok, msg} = Moneda.ver_moneda(parametros_ver)
        assert "\nFin. Se han mostrado todos los datos de la moneda." == msg
      end)
  end

  test "error si faltan flags necesarias al crear_moneda" do
    # falta precio
    parametros = [n: "USDT"]
    {estado, comando, info} = Moneda.crear_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "crear_moneda", "Faltan las siguientes flags necesarias: p"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si el nombre es invalido al crear_moneda" do
    parametros = [n: "REALES", p: 3]
    {estado, comando, info} = Moneda.crear_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "crear_moneda", "El nombre debe tener 3 o 4 letras en mayúsculas"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si monto no positivo al crear_moneda" do
    parametros = [n: "USDT", p: 0]
    {estado, comando, info} = Moneda.crear_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "crear_moneda", "El precio de la moneda debe ser positivo"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si moneda no existe al ver_moneda" do
    parametros = [id: 999]
    {estado, comando, info} = Moneda.ver_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "ver_moneda", "Moneda inexistente"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si faltan flags necesarias al borrar_moneda" do
    # falta id
    parametros = []
    {estado, comando, info} = Moneda.borrar_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "borrar_moneda", "Faltan las siguientes flags necesarias: id"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si moneda no existe al borrar_moneda" do
    parametros = [id: 999]
    {estado, comando, info} = Moneda.borrar_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "borrar_moneda", "Moneda inexistente"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si faltan flags necesarias al editar_moneda" do
    parametros = [id: 10]
    {estado, comando, info} = Moneda.editar_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "editar_moneda", "Faltan las siguientes flags necesarias: p"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si moneda no existe al editar_moneda" do
    parametros = [id: 999, p: 1500]
    {estado, comando, info} = Moneda.editar_moneda(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "editar_moneda", "Moneda inexistente"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si posee transacciones asociadas al borrar_moneda" do
    parametros_crear_usuario = [n: "Julian", b: "2001-01-01"]
    {:ok, _msg} = User.crear_usuario(parametros_crear_usuario)
    usuario = Repo.get_by(User, nombre: "Julian")

    parametros_crear_moneda1 = [n: "USDT", p: 1]
    {:ok, _msg} = Moneda.crear_moneda(parametros_crear_moneda1)
    moneda = Repo.get_by(Moneda, nombre: "USDT")

    parametros_alta_cuenta1 = [u: usuario.id, m: "USDT", a: 100]
    Transaccion.Creacion.alta_cuenta(parametros_alta_cuenta1)

    parametros_borrar = [id: moneda.id]
    {estado, comando, info} = Moneda.borrar_moneda(parametros_borrar)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "borrar_moneda", "La moneda posee transacciones asociadas, no puede ser borrada"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end
end
