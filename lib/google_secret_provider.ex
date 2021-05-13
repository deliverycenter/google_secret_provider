defmodule GoogleSecretProvider do
  @behaviour Config.Provider

  @auth_scope "https://www.googleapis.com/auth/cloud-platform"

  require Logger

  alias GoogleApi.SecretManager.V1.{Api, Connection, Model}

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
      |> Connection.new()
      |> Api.Projects.secretmanager_projects_secrets_versions_access(project_id, secret_id, version)

    case response do
      {:ok, %Model.AccessSecretVersionResponse{payload: %Model.SecretPayload{data: data}}} ->
        decode_secrets!(data)

      {:error, error} ->
        raise "Error fetching secrets from Google API #{inspect(error)}"
    end
  end

  defp decode_secrets!(data) do
    case data |> Base.decode64!() |> Jason.decode() do
      {:ok, secrets} ->
        secrets

      {:error, _error} ->
        raise "Error decoding secrets. Make sure your secret is a valid JSON."
    end
  end

  defp get_auth_token!(scope) do
    case Goth.Token.for_scope(scope) do
      {:ok, %Goth.Token{token: token}} ->
        token

      error ->
        raise "Error fetching token from Goth: #{inspect(error)}"
    end
  end

  defp fetch_json_key!(secrets, json_key) do
    case Map.fetch(secrets, json_key) do
      {:ok, value} ->
        value

      :error ->
        raise "Could not find key #{json_key} in JSON secret payload. All keys specified in configs must be present in secrets"
    end
  end
end
