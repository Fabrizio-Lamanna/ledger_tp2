defmodule Ledger.Executor do
  alias Ledger.Moneda
  alias Ledger.User
  alias Ledger.Transaccion
  alias Ledger.Transaccion.Creacion
  alias Ledger.Transaccion.Ver
  alias Ledger.Transaccion.Deshacer
  alias Ledger.Balance

  @comandos %{
    "crear_usuario" => &User.crear_usuario/1,
    "ver_usuario" => &User.ver_usuario/1,
    "borrar_usuario" => &User.borrar_usuario/1,
    "editar_usuario" => &User.editar_usuario/1,
    "crear_moneda" => &Moneda.crear_moneda/1,
    "ver_moneda" => &Moneda.ver_moneda/1,
    "borrar_moneda" => &Moneda.borrar_moneda/1,
    "editar_moneda" => &Moneda.editar_moneda/1,
    "alta_cuenta" => &Creacion.alta_cuenta/1,
    "realizar_transferencia" => &Creacion.realizar_transferencia/1,
    "realizar_swap" => &Creacion.realizar_swap/1,
    "ver_transaccion" => &Ver.ver_transaccion/1,
    "deshacer_transaccion" => &Deshacer.deshacer_transaccion/1,
    "transacciones" => &Transaccion.transacciones_de_cuenta/1,
    "balance" => &Balance.balance_de_cuenta/1
  }

  def ejecutar_comando(comando, flags) do
    case @comandos[comando] do
      nil ->
        IO.puts("Comando desconocido: #{comando}")

      fun ->
        fun.(flags)
    end
  end
end
