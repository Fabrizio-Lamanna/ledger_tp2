defmodule Ledger.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.Validaciones
  alias Ledger.Repo
  alias Ledger.Utils

  schema "users" do
    field :nombre, :string
    field :fecha_nacimiento, :date
    timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:nombre, :fecha_nacimiento])
    |> validate_required([:nombre, :fecha_nacimiento])
    |> unique_constraint(:nombre)
    |> Validaciones.mayor_de_edad()
  end

  def crear_usuario_con_fecha(nombre, fecha_nacimiento) do
    attrs = %{nombre: nombre, fecha_nacimiento: fecha_nacimiento}
    changeset = changeset(%__MODULE__{}, attrs)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, "Usuario creado con id: #{user.id}"}

      {:error, changeset} ->
        errores = Utils.transformar_errores_para_salida(changeset)
        {:error, "crear_usuario", errores}
    end
  end

  def crear_usuario(parametros) do
    case Validaciones.validar_existencia_de_flags_necesarias(parametros, [:n, :b]) do
      :ok ->
        case Date.from_iso8601(parametros[:b]) do
          {:ok, fecha_nacimiento} ->
            crear_usuario_con_fecha(parametros[:n], fecha_nacimiento)

          {:error, _reason} ->
            {:error, "crear_usuario", "Fecha de nacimiento invalida (formato valido: YYYY-MM-DD)"}
        end

      {:error, info} ->
        {:error, "crear_usuario", info}
    end
  end

  def ver_usuario(parametros) do
    case Ledger.Repo.get(Ledger.User, parametros[:id]) do
      nil ->
        {:error, "ver_usuario", "Usuario inexistente"}

      usuario ->
        mostar_usuario(usuario)
        {:ok, "\nFin. Se han mostrado todos los datos del usuario."}
    end
  end

  def mostar_usuario(usuario) do
    usuario
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.each(fn {key, value} ->
      IO.puts("#{key}: #{value}")
    end)
  end

  def borrar_usuario(parametros) do
    case Validaciones.validar_existencia_de_flags_necesarias(parametros, [:id]) do
      {:error, info} ->
        {:error, "borrar_usuario", info}

      :ok ->
        case Ledger.Repo.get(Ledger.User, parametros[:id]) do
          nil ->
            {:error, "borrar_usuario", "Usuario inexistente"}

          usuario ->
            changeset =
              Ecto.Changeset.change(usuario)
              |> Ecto.Changeset.foreign_key_constraint(:cuenta_origen_id,
                name: "transacciones_cuenta_origen_id_fkey"
              )

            case Repo.delete(changeset) do
              {:ok, _struct} ->
                {:ok, "Usuario borrado correctamente"}

              {:error, _changeset} ->
                {:error, "borrar_usuario",
                 "El usuario posee transacciones asociadas, no puede ser borrado"}
            end
        end
    end
  end

  def editar_usuario(parametros) do
    case Validaciones.validar_existencia_de_flags_necesarias(parametros, [:id, :n]) do
      {:error, info} ->
        {:error, "editar_usuario", info}

      :ok ->
        case Ledger.Repo.get(Ledger.User, parametros[:id]) do
          nil ->
            {:error, "editar_usuario", "Usuario inexistente"}

          usuario ->
            if parametros[:n] == usuario.nombre do
              {:error, "editar_usuario", "El nuevo nombre debe ser distinto al actual"}
            else
              attrs = %{nombre: parametros[:n]}
              changeset = Ledger.User.changeset(usuario, attrs)

              case Ledger.Repo.update(changeset) do
                {:ok, usuario_actualizado} ->
                  {:ok, "Usuario actualizado correctamente: #{usuario_actualizado.nombre}"}

                {:error, changeset} ->
                  errores = Utils.transformar_errores_para_salida(changeset)
                  {:error, "editar_usuario", errores}
              end
            end
        end
    end
  end
end
