defmodule Ledger.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Ledger.CLI

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
    :ok
  end

  test "ejecuta un comando válido y muestra resultado" do
    args = ["crear_usuario", "-n=Lautaro", "-b=2000-01-01"]

    output =
      capture_io(fn ->
        CLI.main(args)
      end)

    assert output =~ "Usuario creado"
  end

  test "muestra error si el comando es inválido" do
    args = ["comando_inexistente"]

    output =
      capture_io(fn ->
        CLI.main(args)
      end)

    assert output =~ "error"
    assert output =~ "comando_inexistente"
  end

  test "muestra error de ejecución si Executor falla" do
    # falta fecha de nacimiento
    args = ["crear_usuario", "-n=Lautaro"]

    output =
      capture_io(fn ->
        CLI.main(args)
      end)

    assert output =~ ":error"
    assert output =~ "crear_usuario"
  end
end
