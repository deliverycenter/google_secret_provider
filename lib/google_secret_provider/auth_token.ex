defmodule GoogleSecretProvider.AuthToken do
  @callback for_scope(String.t()) :: {:ok, String.t()} | {:error, any()}
  def for_scope(scope) do
    case Goth.Token.for_scope(scope) do
      {:ok, %Goth.Token{token: token}} ->
        {:ok, token}

      {:error, error} ->
        {:error, error}
    end
  end
end
