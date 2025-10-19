defmodule Ledger.Parser do
  alias Ledger.Validaciones

  def formatear_entrada(args) when args != [] do
    [comando | argumento] = args

    case argumento do
      [] ->
        {:error, "formato de flags invalido"}

      _ ->
        try do
          flags =
            argumento
            |> Enum.map(fn
              <<"-", rest::binary>> ->
                case String.split(rest, "=", parts: 2) do
                  [clave, valor] -> {String.to_atom(clave), valor}
                  [clave] -> {String.to_atom(clave), true}
                end
            end)

          {:ok, comando, flags}
        rescue
          _error -> {:error, "formato de flags invalido"}
        end
    end
  end

  def formatear_entrada(_args) do
    {:error, "comando ingresado invalido"}
  end

  def parsear_comando(entrada) do
    with {:ok, comando, flags} <- formatear_entrada(entrada),
         :ok <- Validaciones.validar_comando(comando),
         :ok <- Validaciones.validar_flags_aceptadas(flags) do
      {:ok, {comando, flags}}
    else
      {:error, msg} ->
        case entrada do
          [comando | _] ->
            {:error, comando, msg}

          [] ->
            {:error, "Comando vacio", msg}
        end
    end
  end
end
