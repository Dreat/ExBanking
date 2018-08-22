defmodule ExBanking.UserWallet do
  use GenServer

  @decimal_precision 2
  @ets_table_name :users
  # @max_requests_per_user 10

  def start_link(user) do
    create_user_counter(user)
    GenServer.start_link(__MODULE__, %{}, name: {:global, user})
  end

  def init(map) do
    {:ok, map}
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    new_state = add_or_update(state, amount, currency)

    {:reply, get_return_value(new_state, currency), new_state}
  end

  def handle_call({:get_balance, currency}, _from, state) do
    if Map.has_key?(state, currency) do
      {:reply, get_return_value(state, currency), state}
    else
      {:reply, {:ok, 0.0}, Map.put(state, currency, 0.0)}
    end
  end

  def handle_call({:withdraw, amount, currency}, _from, state) do
    if Map.has_key?(state, currency) do
      case try_withdraw(state, amount, currency) do
        {:ok, new_state} -> {:reply, get_return_value(new_state, currency), new_state}
        err -> {:reply, err, state}
      end
    else
      {:reply, {:error, :not_enough_money}, state}
    end
  end

  def deposit(user, amount, currency) do
    with :ok <- check_if_user_exists(user),
         {:ok, new_balance} <- GenServer.call({:global, user}, {:deposit, amount, currency}) do
      :timer.sleep(10_000)
      {:ok, new_balance}
    else
      err -> err
    end
  end

  def get_balance(user, currency) do
    case check_if_user_exists(user) do
      :ok -> GenServer.call({:global, user}, {:get_balance, currency})
      err -> err
    end
  end

  def send(from_user, to_user, amount, currency) do
    case check_if_user_exists(from_user) do
      :ok ->
        case check_if_user_exists(to_user) do
          :ok ->
            case withdraw(from_user, amount, currency) do
              {:ok, from_user_new_balance} ->
                {:ok, to_user_new_balance} = deposit(to_user, amount, currency)
                {:ok, from_user_new_balance, to_user_new_balance}

              err ->
                err
            end

          _ ->
            {:error, :receiver_does_not_exist}
        end

      _ ->
        {:error, :sender_does_not_exist}
    end
  end

  def withdraw(user, amount, currency) do
    case check_if_user_exists(user) do
      :ok -> GenServer.call({:global, user}, {:withdraw, amount, currency})
      err -> err
    end
  end

  defp try_withdraw(state, amount, currency) do
    cond do
      state[currency] - amount < 0 -> {:error, :not_enough_money}
      true -> {:ok, %{state | currency => state[currency] - amount}}
    end
  end

  defp add_or_update(map, amount, currency) do
    if Map.has_key?(map, currency) do
      %{map | currency => map[currency] + amount}
    else
      Map.put(map, currency, amount / 1)
    end
  end

  defp get_return_value(map, currency),
    do: {:ok, map[currency] |> Float.round(@decimal_precision)}

  defp check_if_user_exists(user) do
    case :global.whereis_name(user) do
      :undefined -> {:error, :user_does_not_exist}
      _ -> :ok
    end
  end

  defp create_user_counter(user) do
    unless ets_table_exist?(@ets_table_name) do
      :ets.new(@ets_table_name, [:public, :set, :named_table])
    end

    :ets.insert(@ets_table_name, {user, 0})
  end

  defp ets_table_exist?(table_name) do
    case :ets.info(table_name) do
      :undefined -> false
      _ -> true
    end
  end

  # defp check_user_requests_number(user) do
  #   [{_, counter}] = :ets.match_object(@ets_table_name, {user, :_})

  #   if counter >= @max_requests_per_user do
  #     {:error, :too_many_requests_to_user}
  #   else
  #     :ets.insert(@ets_table_name, {user, counter + 1})
  #     :ok
  #   end
  # end

  # defp decrement_user_requests_counter(user) do
  #   [{_, counter}] = :ets.match_object(@ets_table_name, {user, :_})
  #   :ets.insert(@ets_table_name, {user, counter - 1})
  # end
end
