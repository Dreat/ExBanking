defmodule ExBanking do
  alias ExBanking.UserWallet, as: Wallet

  @type banking_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) when is_bitstring(user) do
    case Wallet.start_link(user) do
      {:ok, _pid} -> :ok
      _ -> {:error, :user_already_exists}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency)
      when is_bitstring(user) and is_number(amount) and is_bitstring(currency),
      do: Wallet.deposit(user, amount, currency)

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency)
      when is_bitstring(user) and is_number(amount) and is_bitstring(currency),
      do: Wallet.withdraw(user, amount, currency)

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) when is_bitstring(user) and is_bitstring(currency),
    do: Wallet.get_balance(user, currency)

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency)
      when is_bitstring(from_user) and is_bitstring(to_user) and is_number(amount) and
             is_bitstring(currency),
      do: Wallet.send(from_user, to_user, amount, currency)

  def send(_, _, _, _), do: {:error, :wrong_arguments}
end
