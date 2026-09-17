defmodule TiannaraRuntime.Civilization.Economy.ScientificCapitalLedger do
  def initialize() do
    {:ok, %{transactions: [], balances: %{}, total_capital: 0}}
  end

  def record_transaction(ledger, from, to, amount, type) do
    tx = %{
      id: :erlang.unique_integer([:positive]),
      from: from,
      to: to,
      amount: amount,
      type: type,
      timestamp: :erlang.unique_integer([:positive])
    }
    from_balance = Map.get(ledger.balances, from, 0)
    to_balance = Map.get(ledger.balances, to, 0)
    new_balances = ledger.balances
    |> Map.put(from, from_balance - amount)
    |> Map.put(to, to_balance + amount)
    {:ok, %{ledger | transactions: [tx | ledger.transactions], balances: new_balances, total_capital: ledger.total_capital + amount}}
  end

  def get_balance(ledger, entity_id) do
    {:ok, Map.get(ledger.balances, entity_id, 0)}
  end

  def verify(ledger) do
    net = Enum.reduce(ledger.transactions, 0, fn tx, acc ->
      acc + Map.get(tx, :amount)
    end)
    {:ok, net == 0}
  end

  def replay(ledger) do
    {:ok, ledger.transactions}
  end
end
