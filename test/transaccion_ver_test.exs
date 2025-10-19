defmodule Ledger.Transaccion.VerTest do
  use ExUnit.Case, async: true
  alias Ledger.{Transaccion, Moneda, User, Repo}
  alias Ledger.Transaccion.Ver
  alias Ledger.Transaccion.Creacion
  import ExUnit.CaptureIO

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Repo.delete_all(Transaccion)
    Repo.delete_all(Moneda)
    Repo.delete_all(User)

    {:ok, _msg} = User.crear_usuario(n: "Pedro", b: "1995-03-10")
    {:ok, _msg} = Moneda.crear_moneda(n: "USD", p: 1.0)

    usuario = Repo.get_by(User, nombre: "Pedro")
    moneda = Repo.get_by(Moneda, nombre: "USD")
    {:ok, _msg} = Creacion.alta_cuenta(u: usuario.id, m: moneda.nombre, a: 100.0)
    transaccion = Repo.one(Transaccion)

    {:ok, usuario: usuario, moneda: moneda, transaccion: transaccion}
  end

  test "ver transaccion imprime correctamente" do
    transaccion = %Ledger.Transaccion{
      id: 1,
      monto: 100.0,
      cuenta_origen_id: 1,
      moneda_origen_id: 1,
      tipo: "alta_cuenta",
      fecha_realizacion: ~N[2025-10-17 21:52:23]
    }

    output =
      capture_io(fn ->
        Ver.mostrar_transaccion(transaccion)
      end)

    assert output =~ "id: 1"
    assert output =~ "monto: 100.0"
    assert output =~ "cuenta_origen_id: 1"
  end

  test "devuelve error al intentar ver una transaccion inexistente" do
    parametros = [id: -1]
    {:error, tipo, mensaje} = Ver.ver_transaccion(parametros)

    assert tipo == "ver_transaccion"
    assert mensaje == "Transaccion inexistente"
  end
end
