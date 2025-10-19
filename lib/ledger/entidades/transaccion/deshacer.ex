defmodule Ledger.Transaccion.Deshacer do
  use Ecto.Schema
  alias Ledger.Validaciones
  alias Ledger.Utils
  alias Ledger.Transaccion.Creacion

  def deshacer_transaccion(parametros) do
    case Validaciones.validar_existencia_de_flags_necesarias(parametros, [:id]) do
      {:error, info} ->
        {:error, "deshacer_transaccion", info}

      :ok ->
        case Ledger.Repo.get(Ledger.Transaccion, parametros[:id]) do
          nil ->
            {:error, "deshacer_transaccion", "La transacción no existe"}

          transaccion ->
            case transaccion.tipo do
              "transferencia" ->
                case deshacer_transferencia(transaccion) do
                  {:error, info} -> {:error, "deshacer_transaccion", info}
                  :ok -> {:ok, "Transaccion deshecha correctamente"}
                end

              "swap" ->
                case deshacer_swap(transaccion) do
                  {:error, info} -> {:error, "deshacer_transaccion", info}
                  :ok -> {:ok, "Transaccion deshecha correctamente"}
                end

              "alta_cuenta" ->
                {:error, "deshacer_transaccion", "No se puede deshacer un alta de cuenta"}
            end
        end
    end
  end

  def deshacer_transferencia(transaccion) do
    case Validaciones.ultima_transaccion_de_cuenta?(
           transaccion.cuenta_origen_id,
           transaccion.moneda_origen_id,
           transaccion.fecha_realizacion
         ) and
           Validaciones.ultima_transaccion_de_cuenta?(
             transaccion.cuenta_destino_id,
             transaccion.moneda_origen_id,
             transaccion.fecha_realizacion
           ) do
      true ->
        moneda = Ledger.Repo.get(Ledger.Moneda, transaccion.moneda_origen_id)

        flags_nueva_transaccion = [
          o: transaccion.cuenta_destino_id,
          d: transaccion.cuenta_origen_id,
          m: moneda.nombre,
          a: Float.to_string(transaccion.monto)
        ]

        Creacion.realizar_transferencia(flags_nueva_transaccion)
        :ok

      false ->
        {:error, "Existen transacciones mas recientes para las cuentas involucradas"}
    end
  end

  def deshacer_swap(transaccion) do
    case Validaciones.ultima_transaccion_de_cuenta?(
           transaccion.cuenta_origen_id,
           transaccion.moneda_origen_id,
           transaccion.fecha_realizacion
         ) and
           Validaciones.ultima_transaccion_de_cuenta?(
             transaccion.cuenta_origen_id,
             transaccion.moneda_destino_id,
             transaccion.fecha_realizacion
           ) do
      true ->
        moneda_origen = Ledger.Repo.get(Ledger.Moneda, transaccion.moneda_origen_id)
        moneda_destino = Ledger.Repo.get(Ledger.Moneda, transaccion.moneda_destino_id)

        monto =
          Utils.calcular_equivalencia_entre_monedas(
            transaccion.monto,
            moneda_origen,
            moneda_destino
          )

        nueva_moneda_origen = moneda_destino
        nueva_moneda_destino = moneda_origen

        flags_nueva_transaccion = [
          u: transaccion.cuenta_origen_id,
          mo: nueva_moneda_origen.nombre,
          md: nueva_moneda_destino.nombre,
          a: monto
        ]

        Creacion.realizar_swap(flags_nueva_transaccion)
        :ok

      false ->
        {:error, "Existen transacciones mas recientes para las cuentas involucradas"}
    end
  end
end
