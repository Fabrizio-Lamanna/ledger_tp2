defmodule Ledger.Validaciones do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.Repo
  import Ecto.Query

  # ----------CHANGESET'S----------

  def validar_alta_cuenta_unica(changeset) do
    cuenta_id = get_field(changeset, :cuenta_origen_id)
    moneda_id = get_field(changeset, :moneda_origen_id)

    if cuenta_id && moneda_id do
      existe? =
        Ledger.Repo.exists?(
          from t in Ledger.Transaccion,
            where:
              t.cuenta_origen_id == ^cuenta_id and
                t.moneda_origen_id == ^moneda_id and
                t.tipo == "alta_cuenta"
        )

      if existe? do
        add_error(changeset, :moneda_origen_id, "Cuenta ya existe")
      else
        changeset
      end
    else
      changeset
    end
  end

  def mayor_de_edad(changeset) do
    fecha_nacimiento = get_field(changeset, :fecha_nacimiento)
    edad = Date.diff(Date.utc_today(), fecha_nacimiento)

    if edad < 18 * 365 do
      add_error(changeset, :fecha_nacimiento, "El usuario debe ser mayor de edad")
    else
      changeset
    end
  end

  def precio_positivo(changeset) do
    precio = get_field(changeset, :precio)

    if precio <= 0 do
      add_error(changeset, :precio, "El precio de la moneda debe ser positivo")
    else
      changeset
    end
  end

  def nombre_valido(changeset) do
    nombre = get_field(changeset, :nombre)

    if nombre && Regex.match?(~r/^[A-Z]{3,4}$/, nombre) do
      changeset
    else
      add_error(changeset, :nombre, "El nombre debe tener 3 o 4 letras en mayúsculas")
    end
  end

  # ----------PARSER----------

  def validar_comando(comando)
      when comando in [
             "crear_usuario",
             "editar_usuario",
             "borrar_usuario",
             "ver_usuario",
             "crear_moneda",
             "editar_moneda",
             "borrar_moneda",
             "ver_moneda",
             "alta_cuenta",
             "realizar_transferencia",
             "realizar_swap",
             "deshacer_transaccion",
             "ver_transaccion",
             "balance",
             "transacciones"
           ],
      do: :ok

  def validar_comando(_comando) do
    {:error, "comando ingresado invalido"}
  end

  def validar_flags_aceptadas(flags) do
    validas = [:n, :b, :id, :p, :u, :m, :a, :o, :d, :mo, :md, :c1, :c2]

    with :ok <- validar_flags_validas(flags, validas) do
      :ok
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def validar_flags_validas(flags, validas) do
    case Enum.all?(flags, fn {clave, _valor} -> clave in validas end) do
      true -> :ok
      false -> {:error, "flags ingresadas invalidas"}
    end
  end

  # ----------FLAGS-PARA-COMANDO----------

  def validar_existencia_de_flags_necesarias(flags_ingresadas, flags_necesarias) do
    keys_ingresadas = Keyword.keys(flags_ingresadas)
    faltantes = flags_necesarias -- keys_ingresadas

    case faltantes do
      [] ->
        :ok

      _ ->
        {:error, "Faltan las siguientes flags necesarias: #{Enum.join(faltantes, ", ")}"}
    end
  end

  def validar_flags_alta_cuenta(flags) do
    with :ok <- validar_existencia_de_flags_necesarias(flags, [:u, :m, :a]),
         :ok <- validar_moneda_existente(flags[:m]),
         :ok <- validar_usuario_existente(flags[:u]),
         :ok <- validar_monto_positivo(flags[:a]) do
      :ok
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def validar_flags_realizar_transferencia(flags) do
    with :ok <- validar_existencia_de_flags_necesarias(flags, [:o, :d, :m, :a]),
         :ok <- validar_moneda_existente(flags[:m]),
         :ok <- validar_usuario_existente(flags[:o]),
         :ok <- validar_usuario_existente(flags[:d]),
         :ok <- validar_monto_positivo(flags[:a]),
         :ok <- validar_cuenta_existente(flags[:o], flags[:m]),
         :ok <- validar_cuenta_existente(flags[:d], flags[:m]) do
      :ok
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def validar_flags_realizar_swap(flags) do
    with :ok <- validar_existencia_de_flags_necesarias(flags, [:u, :mo, :md, :a]),
         :ok <- validar_moneda_existente(flags[:mo]),
         :ok <- validar_moneda_existente(flags[:md]),
         :ok <- validar_usuario_existente(flags[:u]),
         :ok <- validar_monto_positivo(flags[:a]),
         :ok <- validar_cuenta_existente(flags[:u], flags[:mo]),
         :ok <- validar_cuenta_existente(flags[:u], flags[:md]) do
      :ok
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def validar_flags_recopilar_transacciones(flags) do
    with :ok <- validar_existencia_de_flags_necesarias(flags, [:c1]),
         :ok <- validar_usuario_existente(flags[:c1]) do
      :ok
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def validar_flags_balance(flags) do
    with :ok <- validar_existencia_de_flags_necesarias(flags, [:c1]),
         :ok <- validar_usuario_existente(flags[:c1]) do
      :ok
    else
      {:error, msg} -> {:error, msg}
    end
  end

  # ----------UNITARIAS----------

  def validar_usuario_existente(usuario_id) do
    case usuario_id do
      nil ->
        {:error, "El usuario no fue especificado"}

      id ->
        if Repo.exists?(from u in Ledger.User, where: u.id == ^id) do
          :ok
        else
          {:error, "Usuario inexistente"}
        end
    end
  end

  @spec validar_moneda_existente(nil | binary()) :: :ok | {:error, <<_::144, _::_*88>>}
  def validar_moneda_existente(nombre_moneda) do
    case nombre_moneda do
      nil ->
        {:error, "La moneda no fue especificada"}

      nombre when is_binary(nombre) ->
        if Repo.exists?(from m in Ledger.Moneda, where: m.nombre == ^nombre) do
          :ok
        else
          {:error, "Moneda inexistente"}
        end
    end
  end

  def validar_monto_positivo(monto) when is_number(monto) do
    if monto > 0 do
      :ok
    else
      {:error, "El monto debe ser positivo"}
    end
  end

  def validar_monto_positivo(monto) when is_binary(monto) do
    case Float.parse(monto) do
      {num, ""} ->
        if num > 0 do
          :ok
        else
          {:error, "El monto debe ser positivo"}
        end

      _ ->
        {:error, "El monto debe ser un valor numerico"}
    end
  end

  def validar_monto_positivo(_), do: {:error, "El monto debe ser un valor numerico"}

  def validar_cuenta_existente(user_id, moneda_nombre) do
    moneda = Repo.get_by(Ledger.Moneda, nombre: moneda_nombre)

    cond do
      moneda == nil ->
        {:error, "La moneda #{moneda_nombre} no existe"}

      not Repo.exists?(
        from t in Ledger.Transaccion,
          where:
            t.cuenta_origen_id == ^user_id and
              t.moneda_origen_id == ^moneda.id and
                t.tipo == "alta_cuenta"
      ) ->
        {:error, "La cuenta (usuario id: #{user_id}, moneda: #{moneda_nombre}) no existe"}

      true ->
        :ok
    end
  end

  def ultima_transaccion_de_cuenta?(user_id, moneda_id, fecha_realizacion) do
    query =
      from(t in Ledger.Transaccion,
        where:
          t.fecha_realizacion > ^fecha_realizacion and
            (t.cuenta_origen_id == ^user_id or
               (not is_nil(t.cuenta_destino_id) and t.cuenta_destino_id == ^user_id)) and
            (t.moneda_origen_id == ^moneda_id or
               (not is_nil(t.moneda_destino_id) and t.moneda_destino_id == ^moneda_id)),
        select: count(t.id)
      )

    existe_mas_reciente = Ledger.Repo.one(query)

    if existe_mas_reciente > 0 do
      false
    else
      true
    end
  end
end
