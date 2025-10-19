defmodule Ledger.Transaccion do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.Validaciones
  import Ecto.Query

  schema "transacciones" do
    belongs_to :moneda_origen, Ledger.Moneda
    belongs_to :moneda_destino, Ledger.Moneda
    field :monto, :float
    belongs_to :cuenta_origen, Ledger.User
    belongs_to :cuenta_destino, Ledger.User
    field :tipo, :string

    timestamps(inserted_at: :fecha_realizacion, updated_at: false)
  end

  def alta_cuenta_changeset(transaccion, attrs) do
    transaccion
    |> cast(attrs, [:moneda_origen_id, :monto, :cuenta_origen_id, :tipo])
    |> validate_required([:moneda_origen_id, :monto, :cuenta_origen_id, :tipo])
    |> Validaciones.validar_alta_cuenta_unica()
  end

  def realizar_transferencia_changeset(transaccion, attrs) do
    transaccion
    |> cast(attrs, [:moneda_origen_id, :monto, :cuenta_origen_id, :cuenta_destino_id, :tipo])
    |> validate_required([:moneda_origen_id, :monto, :cuenta_origen_id, :cuenta_destino_id, :tipo])
  end

  def realizar_swap_changeset(transaccion, attrs) do
    transaccion
    |> cast(attrs, [:moneda_origen_id, :moneda_destino_id, :monto, :cuenta_origen_id, :tipo])
    |> validate_required([:moneda_origen_id, :moneda_destino_id, :monto, :cuenta_origen_id, :tipo])
  end

  # ----------REPORTE_TRANSACCIONES----------

  def transacciones_de_cuenta(parametros) do
    case Validaciones.validar_flags_recopilar_transacciones(parametros) do
      {:error, info} ->
        {:error, "transacciones", info}

      :ok ->
        c1 = parametros[:c1]
        c2 = parametros[:c2]
        query = filtrar_transacciones_segun_parametros(c1, c2)
        transacciones = Ledger.Repo.all(query)
        transacciones = formatear_transacciones(transacciones)
        mostrar_transacciones(transacciones)
        {:ok, "\nSe han mostrado todas las transacciones"}
    end
  end

  def filtrar_transacciones_segun_parametros(c1, c2) do
    query =
      case c2 do
        nil ->
          from t in Ledger.Transaccion,
            where: t.cuenta_origen_id == ^c1 or t.cuenta_destino_id == ^c1,
            preload: [:cuenta_origen, :cuenta_destino, :moneda_origen, :moneda_destino]

        _ ->
          from t in Ledger.Transaccion,
            where: t.cuenta_origen_id == ^c1 and t.cuenta_destino_id == ^c2,
            preload: [:cuenta_origen, :cuenta_destino, :moneda_origen, :moneda_destino]
      end

    query
  end

  def formatear_transacciones(transacciones) do
    Enum.map(transacciones, fn t ->
      %{
        id: t.id,
        tipo: t.tipo,
        monto: t.monto,
        fecha: t.fecha_realizacion,
        cuenta_origen: if(t.cuenta_origen, do: t.cuenta_origen.nombre, else: nil),
        cuenta_destino: if(t.cuenta_destino, do: t.cuenta_destino.nombre, else: nil),
        moneda_origen: if(t.moneda_origen, do: t.moneda_origen.nombre, else: nil),
        moneda_destino: if(t.moneda_destino, do: t.moneda_destino.nombre, else: nil)
      }
    end)
  end

  def mostrar_transacciones(transacciones) do
    transacciones
    |> Enum.each(fn t ->
      IO.puts(
        "#{t.tipo}, #{t.monto}, #{t.cuenta_origen}, #{t.cuenta_destino}, #{t.moneda_origen}, #{t.moneda_destino}, #{t.fecha}"
      )
    end)
  end
end
