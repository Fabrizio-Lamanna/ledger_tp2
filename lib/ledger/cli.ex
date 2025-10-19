defmodule Ledger.CLI do
  alias Ledger.Parser
  alias Ledger.Executor

  def main(args) do
    {:ok, _} = Application.ensure_all_started(:ledger)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.ensure_all_started(:postgrex)

    with {:ok, {comando, flags}} <- Parser.parsear_comando(args),
         {:ok, resultado} <- Executor.ejecutar_comando(comando, flags) do
      IO.puts(resultado)
    else
      {:error, comando, msg} ->
        IO.puts(":error, #{comando}, #{msg}")
    end
  end
end
