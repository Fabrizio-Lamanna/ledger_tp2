defmodule ParserTest do
  use ExUnit.Case
  alias Ledger.Parser

  test "formatea entrada correctamente con flags con valores" do
    entrada = ["transacciones", "-c1=userA", "-c2=userB"]
    {:ok, comando, flags} = Parser.formatear_entrada(entrada)
    comando_esperado = "transacciones"
    flags_esperadas = [c1: "userA", c2: "userB"]

    assert comando == comando_esperado
    assert flags == flags_esperadas
  end

  test "parsea comando y flags correctamente" do
    entrada = ["crear_usuario", "-n=pedro", "-b=2000-05-30"]
    {_estado, {comando, flags}} = Parser.parsear_comando(entrada)
    comando_esperado = "crear_usuario"
    flags_esperadas = [n: "pedro", b: "2000-05-30"]

    assert comando == comando_esperado
    assert flags == flags_esperadas
  end

  test "detecta comando inexistnte al parsear entrada" do
    entrada = ["comando_inexistente", "-a=100"]

    {estado_esperado, comando_esperado, msg_esperado} =
      {:error, "comando_inexistente", "comando ingresado invalido"}

    {estado_obtenido, comando_obtenido, msg_obtenido} = Parser.parsear_comando(entrada)

    assert {estado_esperado, comando_esperado, msg_esperado} ==
             {estado_obtenido, comando_obtenido, msg_obtenido}
  end

  test "detecta flag invalida al parsear entrada" do
    entrada = ["crear_moneda", "-n=Julian", "-esta_flag=_es_invalida"]

    {estado_esperado, comando_esperado, msg_esperado} =
      {:error, "crear_moneda", "flags ingresadas invalidas"}

    {estado_obtenido, comando_obtenido, msg_obtenido} = Parser.parsear_comando(entrada)

    assert {estado_esperado, comando_obtenido, msg_esperado} ==
             {estado_obtenido, comando_esperado, msg_obtenido}
  end

  test "detecta formato de flag invalido al formatear entrada" do
    entrada = ["editar_usuario", "-id=10", "-n=Matias", "esto no tiene el formato de flag"]
    {estado_esperado, msg_esperado} = {:error, "formato de flags invalido"}
    {estado_obtenido, msg_obtenido} = Parser.formatear_entrada(entrada)

    assert {estado_obtenido, msg_obtenido} == {estado_esperado, msg_esperado}
  end

  test "entrada vacia devuelve error" do
    args = []

    {estado_esperado, comando_esperado, msg_esperado} =
      {:error, "Comando vacio", "comando ingresado invalido"}

    {estado_obtenido, comando_obtenido, msg_obtenido} = Parser.parsear_comando(args)

    assert {estado_esperado, comando_esperado, msg_esperado} ==
             {estado_obtenido, comando_obtenido, msg_obtenido}
  end
end
