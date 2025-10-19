defmodule Ledger.Moneda do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.Validaciones
  alias Ledger.Repo
  alias Ledger.Utils

  schema "monedas" do
    field :nombre, :string
    field :precio, :float
    timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
  end

  def changeset(moneda, attrs) do
    moneda
    |> cast(attrs, [:nombre, :precio])
    |> validate_required([:nombre, :precio])
    |> unique_constraint(:nombre)
    |> Validaciones.precio_positivo()
    |> Validaciones.nombre_valido()
  end

  def crear_moneda_con_nombre_y_precio(nombre, precio) do
    attrs = %{nombre: nombre, precio: precio}
    changeset = changeset(%__MODULE__{}, attrs)

    case Repo.insert(changeset) do
      {:ok, moneda} ->
        {:ok, "Moneda creada con id: #{moneda.id}"}

      {:error, changeset} ->
        errores = Utils.transformar_errores_para_salida(changeset)
        {:error, "crear_moneda", errores}
    end
  end

  def crear_moneda(parametros) do
    case Validaciones.validar_existencia_de_flags_necesarias(parametros, [:n, :p]) do
      :ok -> crear_moneda_con_nombre_y_precio(parametros[:n], parametros[:p])
      {:error, info} -> {:error, "crear_moneda", info}
    end
  end

  def ver_moneda(parametros) do
    case Ledger.Repo.get(Ledger.Moneda, parametros[:id]) do
      nil ->
        {:error, "ver_moneda", "Moneda inexistente"}

      moneda ->
        mostar_moneda(moneda)
        {:ok, "\nFin. Se han mostrado todos los datos de la moneda."}
    end
  end

  def mostar_moneda(moneda) do
    moneda
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.each(fn {key, value} ->
      IO.puts("#{key}: #{value}")
    end)
  end

  def borrar_moneda(parametros) do
    case Validaciones.validar_existencia_de_flags_necesarias(parametros, [:id]) do
      {:error, info} ->
        {:error, "borrar_moneda", info}

      :ok ->
        case Ledger.Repo.get(Ledger.Moneda, parametros[:id]) do
          nil ->
            {:error, "borrar_moneda", "Moneda inexistente"}

          moneda ->
            changeset =
              Ecto.Changeset.change(moneda)
              |> Ecto.Changeset.foreign_key_constraint(:moneda_origen_id,
                name: "transacciones_moneda_origen_id_fkey"
              )
              |> Ecto.Changeset.foreign_key_constraint(:moneda_destino_id,
                name: "transacciones_moneda_destino_id_fkey"
              )

            case Ledger.Repo.delete(changeset) do
              {:ok, _struct} ->
                {:ok, "Moneda borrada correctamente"}

              {:error, _changeset} ->
                {:error, "borrar_moneda",
                 "La moneda posee transacciones asociadas, no puede ser borrada"}
            end
        end
    end
  end

  def editar_moneda(parametros) do
    case Validaciones.validar_existencia_de_flags_necesarias(parametros, [:id, :p]) do
      {:error, info} ->
        {:error, "editar_moneda", info}

      :ok ->
        case Ledger.Repo.get(Ledger.Moneda, parametros[:id]) do
          nil ->
            {:error, "editar_moneda", "Moneda inexistente"}

          moneda ->
            attrs = %{precio: parametros[:p]}
            changeset = Ledger.Moneda.changeset(moneda, attrs)

            case Ledger.Repo.update(changeset) do
              {:ok, moneda_actualizada} ->
                {:ok, "Moneda actualizada correctamente: #{moneda_actualizada.nombre}"}

              {:error, changeset} ->
                errores = Utils.transformar_errores_para_salida(changeset)
                {:error, "editar_moneda", errores}
            end
        end
    end
  end
end
