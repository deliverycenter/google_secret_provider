import Config

config(:google_secret_provider,
  api_client: GoogleSecretProvider.MockApiClient,
  auth_token: GoogleSecretProvider.MockAuthToken
)

config :goth, disabled: true