defmodule GoogleSecretProvider.ApiClient do

  alias GoogleApi.SecretManager.V1.{Api, Connection, Model}

  @callback fetch_secrets(String.t(), String.t(), String.t(), String.t()) :: any
  def fetch_secrets(token, project_id, secret_id, version \\ "latest") do
    response =
      token
      |> Connection.new()
      |> Api.Projects.secretmanager_projects_secrets_versions_access(project_id, secret_id, version)

    case response do
      {:ok, %Model.AccessSecretVersionResponse{payload: %Model.SecretPayload{data: data}}} ->
        {:ok, data}

      {:error, error} ->
        {:error, error}
    end
  end
end
