ExUnit.start()

Mox.defmock(GoogleSecretProvider.MockApiClient, for: GoogleSecretProvider.ApiClient)
Mox.defmock(GoogleSecretProvider.MockAuthToken, for: GoogleSecretProvider.AuthToken)