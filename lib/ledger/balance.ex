defmodule Ledger.Balance do
  alias Ledger.Utils
  use Ecto.Schema
  alias Ledger.Validaciones
  import Ecto.Query
  alias Ledger.Balance
  alias Ledger.Transaccion

  def crear_balance_inicial() do
    monedas = Ledger.Repo.all(Ledger.Moneda)

    Enum.reduce(monedas, %{}, fn moneda, acc ->
      Map.put(acc, moneda.id, 0.0)
    end)
  end

  def modificar_balance(balance, transaccion, _user_id) when transaccion.tipo == "alta_cuenta" do
    balance
    |> Map.update!(transaccion.moneda_origen.id, fn valor_actual ->
      valor_actual + transaccion.monto
    end)
  end

  def modificar_balance(balance, transaccion, user_id) when transaccion.tipo == "transferencia" do
    user_id = String.to_integer(user_id)

    cond do
      user_id == transaccion.cuenta_origen.id ->
        Map.update!(balance, transaccion.moneda_origen.id, fn valor_actual ->
          valor_actual - transaccion.monto
        end)

      user_id == transaccion.cuenta_destino.id ->
        Map.update!(balance, transaccion.moneda_origen.id, fn valor_actual ->
          valor_actual + transaccion.monto
        end)
    end
  end

  def modificar_balance(balance, transaccion, _user_id) when transaccion.tipo == "swap" do
    incremento_moneda_destino =
      Utils.calcular_equivalencia_entre_monedas(
        transaccion.monto,
        transaccion.moneda_origen,
        transaccion.moneda_destino
      )

    balance
    |> Map.update!(transaccion.moneda_origen.id, fn valor_actual ->
      valor_actual - transaccion.monto
    end)
    |> Map.update!(transaccion.moneda_destino.id, fn valor_actual ->
      valor_actual + incremento_moneda_destino
    end)
  end

  def balance_de_cuenta(parametros) do
    case Validaciones.validar_flags_balance(parametros) do
      {:error, info} ->
        {:error, "balance", info}

      :ok ->
        c1 = parametros[:c1]
        balance_inicial = Balance.crear_balance_inicial()

        transacciones_de_cuenta =
          Transaccion.filtrar_transacciones_segun_parametros(c1, nil) |> Ledger.Repo.all()

        balance_final =
          Enum.reduce(transacciones_de_cuenta, balance_inicial, fn t, acc ->
            Ledger.Balance.modificar_balance(acc, t, c1)
          end)

        case parametros[:m] do
          nil ->
            monedas_activas = monedas_activas_de_usuario(parametros[:c1])
            mostrar_balance(balance_final, monedas_activas)

          moneda ->
            case normalizar_balance_a_moneda(balance_final, moneda) do
              {:ok, balance_normalizado} ->
                IO.puts(balance_normalizado)

              {:error, info} ->
                {:error, "balance", info}
            end
        end

        {:ok, "\nBalance mostrado"}
    end
  end

  def normalizar_balance_a_moneda(balance_map, moneda_destino_nombre) do
    case Validaciones.validar_moneda_existente(moneda_destino_nombre) do
      {:error, info} ->
        {:error, info}

      :ok ->
        moneda_destino = Ledger.Repo.get_by(Ledger.Moneda, nombre: moneda_destino_nombre)
        monedas = Ledger.Repo.all(Ledger.Moneda) |> Map.new(&{&1.id, &1.precio})

        balance_normalizado =
          Enum.reduce(balance_map, 0.0, fn {id_moneda, monto}, acc ->
            precio_moneda = Map.fetch!(monedas, id_moneda)
            precio_destino = moneda_destino.precio
            acc + monto * precio_moneda / precio_destino
          end)

        {:ok, balance_normalizado}
    end
  end

  def mostrar_balance(balance, monedas_activas) do
    balance
    |> Enum.filter(fn {moneda_id, _monto} -> moneda_id in monedas_activas end)
    |> Enum.each(fn {moneda_id, monto} ->
      IO.puts("#{moneda_id}=#{:erlang.float_to_binary(monto, decimals: 6)}")
    end)
  end

  def monedas_activas_de_usuario(user_id) do
    query =
      from t in Ledger.Transaccion,
        where: t.tipo == "alta_cuenta" and t.cuenta_origen_id == ^user_id,
        select: t.moneda_origen_id

    Ledger.Repo.all(query)
  end
end
