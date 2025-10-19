defmodule Ledger.Transaccion.Creacion do
  use Ecto.Schema
  alias Ledger.Repo
  alias Ledger.Validaciones
  alias Ledger.Utils
  alias Ledger.Transaccion

  def alta_cuenta(parametros) do
    case Validaciones.validar_flags_alta_cuenta(parametros) do
      {:error, info} ->
        {:error, "alta_cuenta", info}
      :ok ->
        moneda = Ledger.Repo.get_by(Ledger.Moneda, nombre: parametros[:m])
        attrs = %{
          cuenta_origen_id: parametros[:u],
          moneda_origen_id: moneda.id,
          monto: parametros[:a],
          tipo: "alta_cuenta"
        }
        changeset = Transaccion.alta_cuenta_changeset(%Transaccion{}, attrs)
        case Repo.insert(changeset) do
          {:ok, transaccion} ->
            {:ok, "Transaccion alta_cuenta creada con id: #{transaccion.id}"}
          {:error, changeset} ->
            errores = Utils.transformar_errores_para_salida(changeset)
            {:error, "alta_cuenta", errores}
        end
    end
  end

  def realizar_transferencia(parametros) do
    case Validaciones.validar_flags_realizar_transferencia(parametros) do
      {:error, info} ->
        {:error, "realizar_transferencia", info}
      :ok ->
        moneda = Ledger.Repo.get_by(Ledger.Moneda, nombre: parametros[:m])
        monto = Utils.convertir_a_float(parametros[:a])
        attrs = %{
          cuenta_origen_id: parametros[:o],
          cuenta_destino_id: parametros[:d],
          moneda_origen_id: moneda.id,
          monto: monto,
          tipo: "transferencia"
        }
        changeset = Transaccion.realizar_transferencia_changeset(%Transaccion{}, attrs)
        case Repo.insert(changeset) do
          {:ok, transaccion} ->
            {:ok, "Transferencia creada con id: #{transaccion.id}"}
          {:error, changeset} ->
            errores = Utils.transformar_errores_para_salida(changeset)
            {:error, "realizar_swap", errores}
        end
    end
  end

  def realizar_swap(parametros) do
    case Validaciones.validar_flags_realizar_swap(parametros) do
      {:error, info} ->
        {:error, "realizar_swap", info}
      :ok ->
        moneda_origen = Ledger.Repo.get_by(Ledger.Moneda, nombre: parametros[:mo])
        moneda_destino = Ledger.Repo.get_by(Ledger.Moneda, nombre: parametros[:md])
        monto = Utils.convertir_a_float(parametros[:a])
        attrs = %{
          cuenta_origen_id: parametros[:u],
          moneda_origen_id: moneda_origen.id,
          moneda_destino_id: moneda_destino.id,
          monto: monto,
          tipo: "swap"
        }
        changeset = Transaccion.realizar_swap_changeset(%Transaccion{}, attrs)
        case Repo.insert(changeset) do
          {:ok, transaccion} ->
            {:ok, "Swap creado con id: #{transaccion.id}"}
          {:error, changeset} ->
            errores = Utils.transformar_errores_para_salida(changeset)
            {:error, "realizar_swap", errores}
        end
    end
  end
end
