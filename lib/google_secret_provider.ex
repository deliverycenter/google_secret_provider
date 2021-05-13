defmodule GoogleSecretProvider do
  @behaviour Config.Provider

  @auth_scope "https://www.googleapis.com/auth/cloud-platform"

  require Logger

  alias GoogleSecretProvider.Exception

  def init(config), do: config

  def load(config, %{project_id: project_id, secret_id: secret_id}) do
    # Start all dependent applications
    {:ok, _} = Application.ensure_all_started(:jason)
    {:ok, _} = Application.ensure_all_started(:goth)
    {:ok, _} = Application.ensure_all_started(:tesla)

    updated_configs =
      project_id
      |> fetch_secrets!(secret_id)
      |> replace_tags!(config)

    Logger.debug("Application secrets from loaded with success Google Secret Manager")

    Config.Reader.merge(
      config,
      updated_configs
    )
  end

  defp replace_tags!(secrets, config) do
    Enum.reduce(config, [], fn val, acc ->
      case val do
        {key, {:google_secret, json_key}} ->
          acc ++ [{key, fetch_json_key!(secrets, json_key)}]

        {key, value} when is_list(value) ->
          acc ++ [{key, replace_tags!(secrets, value)}]

        other ->
          acc ++ [other]
      end
    end)
  end

  defp fetch_secrets!(project_id, secret_id, version \\ "latest") do
    response =
      @auth_scope
      |> get_auth_token!()
      |> api_client().fetch_secrets(project_id, secret_id, version)

    case response do
      {:ok, data} ->
        decode_secrets!(data)

      {:error, error} ->
        raise Exception, message: "Error fetching secrets from Google API: #{inspect(error)}"
    end
  end

  defp decode_secrets!(data) do
    case data |> Base.decode64!() |> Jason.decode() do
      {:ok, secrets} ->
        secrets

      {:error, _error} ->
        raise Exception, message: "Error decoding secrets. Make sure your secret is a valid JSON."
    end
  end

  defp get_auth_token!(scope) do
    case auth_token().for_scope(scope) do
      {:ok, token} ->
        token

      {:error, error} ->
        raise Exception, message: "Error fetching token from Goth: #{inspect(error)}"
    end
  end

  defp fetch_json_key!(secrets, json_key) do
    case Map.fetch(secrets, json_key) do
      {:ok, value} ->
        value

      :error ->
        raise Exception, message: "Could not find key '#{json_key}' in JSON secret payload"
    end
  end

  defp api_client(), do: Application.get_env(:google_secret_provider, :api_client, GoogleSecretProvider.ApiClient)
  defp auth_token(), do: Application.get_env(:google_secret_provider, :auth_token, GoogleSecretProvider.AuthToken)
end
