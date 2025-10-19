defmodule Ledger.Transaccion.Ver do
  use Ecto.Schema

  def ver_transaccion(parametros) do
    case Ledger.Repo.get(Ledger.Transaccion, parametros[:id]) do
      nil ->
        {:error, "ver_transaccion", "Transaccion inexistente"}

      transaccion ->
        mostrar_transaccion(transaccion)
        {:ok, "\nFin. Se han mostrado todos los datos de la transaccion."}
    end
  end

  def mostrar_transaccion(transaccion) do
    transaccion
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.each(fn {key, value} ->
      cond do
        is_nil(value) -> :ok
        match?(%Ecto.Association.NotLoaded{}, value) -> :ok
        true -> IO.puts("#{key}: #{value}")
      end
    end)
  end
end
