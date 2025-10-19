defmodule Ledger.UserTest do
  use ExUnit.Case, async: true
  alias Ledger.Transaccion
  alias Ledger.{User, Repo, Moneda}
  alias Ledger.Repo
  import ExUnit.CaptureIO

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Repo.delete_all(Ledger.Transaccion)
    Repo.delete_all(User)
    Repo.delete_all(Moneda)
    :ok
  end

  test "se crea usuario correctamente" do
    parametros = [n: "Agustin", b: "2002-02-15"]
    {:ok, msg} = User.crear_usuario(parametros)
    assert String.contains?(msg, "Usuario creado con id:")
    usuario = Repo.get_by(User, nombre: "Agustin")

    assert usuario.nombre == "Agustin"
  end

  test "se edita un usuario correctamente" do
    parametros_creacion = [n: "Agustin", b: "2002-02-15"]
    {:ok, _msg} = User.crear_usuario(parametros_creacion)
    usuario = Repo.get_by(User, nombre: "Agustin")
    id = usuario.id
    parametros_edicion = [id: id, n: "AgustinFernandez"]
    {:ok, msg} = User.editar_usuario(parametros_edicion)
    usuario_actualizado = Repo.get(User, id)

    assert "Usuario actualizado correctamente: AgustinFernandez" == msg
    assert usuario_actualizado.nombre == "AgustinFernandez"
  end

  test "se borra correctamente un usuario" do
    parametros_creacion = [n: "Agustin", b: "2002-02-15"]
    {:ok, _msg} = User.crear_usuario(parametros_creacion)
    usuario = Repo.get_by(User, nombre: "Agustin")
    id = usuario.id
    parametros_borrar = [id: id]
    {:ok, msg} = User.borrar_usuario(parametros_borrar)
    assert "Usuario borrado correctamente" == msg
  end

  test "se muestra correctamente un usuario" do
    parametros_creacion = [n: "Agustin", b: "2002-02-15"]
    {:ok, _msg} = User.crear_usuario(parametros_creacion)
    usuario = Repo.get_by(User, nombre: "Agustin")
    id = usuario.id
    parametros_ver = [id: id]

    _output =
      capture_io(fn ->
        {:ok, msg} = User.ver_usuario(parametros_ver)
        assert "\nFin. Se han mostrado todos los datos del usuario." == msg
      end)
  end

  test "error si faltan flags necesarias al crear_usuario" do
    # falta fecha de nacimiento
    parametros = [n: "Hernan"]
    {estado, comando, info} = User.crear_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "crear_usuario", "Faltan las siguientes flags necesarias: b"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si fecha de nacimiento es invalida al crear_usuario" do
    # formato de fecha invalido
    parametros = [n: "Hernan", b: "01/01/2001"]
    {estado, comando, info} = User.crear_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "crear_usuario", "Fecha de nacimiento invalida (formato valido: YYYY-MM-DD)"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si el usuario no es mayor de edad al crear_usuario" do
    parametros = [n: "Hernan", b: "2020-01-01"]
    {estado, comando, info} = User.crear_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "crear_usuario", "El usuario debe ser mayor de edad"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si el usuario no existe al ver_usuario" do
    parametros = [id: 999]
    {estado, comando, info} = User.ver_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "ver_usuario", "Usuario inexistente"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si faltan flags necesarias al borrar_usuario" do
    # falta id
    parametros = []
    {estado, comando, info} = User.borrar_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "borrar_usuario", "Faltan las siguientes flags necesarias: id"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si usuario no existe al borrar_usuario" do
    # falta id
    parametros = [id: 999]
    {estado, comando, info} = User.borrar_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "borrar_usuario", "Usuario inexistente"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si posee transacciones asociadas al borrar_usuario" do
    parametros_crear_usuario = [n: "Julian", b: "2001-01-01"]
    {:ok, _msg} = User.crear_usuario(parametros_crear_usuario)
    usuario = Repo.get_by(User, nombre: "Julian")

    parametros_crear_moneda1 = [n: "USDT", p: 1]
    {:ok, _msg} = Moneda.crear_moneda(parametros_crear_moneda1)

    parametros_alta_cuenta1 = [u: usuario.id, m: "USDT", a: 100]
    Transaccion.Creacion.alta_cuenta(parametros_alta_cuenta1)

    parametros_borrar = [id: usuario.id]
    {estado, comando, info} = User.borrar_usuario(parametros_borrar)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "borrar_usuario", "El usuario posee transacciones asociadas, no puede ser borrado"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si faltan flags necesarias al editar_usuario" do
    # falta nuevo nombre
    parametros = [id: 999]
    {estado, comando, info} = User.editar_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "editar_usuario", "Faltan las siguientes flags necesarias: n"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si usuario no existe al editar_usuario" do
    parametros = [id: 999, n: "Juan"]
    {estado, comando, info} = User.editar_usuario(parametros)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "editar_usuario", "Usuario inexistente"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end

  test "error si nuevo nombre no es distinto al editar_usuario" do
    parametros_crear_usuario = [n: "Julian", b: "2001-01-01"]
    {:ok, _msg} = User.crear_usuario(parametros_crear_usuario)
    usuario = Repo.get_by(User, nombre: "Julian")

    parametros_editar = [id: usuario.id, n: "Julian"]
    {estado, comando, info} = User.editar_usuario(parametros_editar)

    {estado_esperado, comando_esperado, info_esperada} =
      {:error, "editar_usuario", "El nuevo nombre debe ser distinto al actual"}

    assert {estado, comando, info} == {estado_esperado, comando_esperado, info_esperada}
  end
end
