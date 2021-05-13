defmodule GoogleSecretProviderTest do
  use ExUnit.Case
  doctest GoogleSecretProvider

  import Mox

  setup :verify_on_exit!

  @valid_secrets "test/support/secrets-valid.json" |> File.read!() |> Base.encode64()
  @invalid_secrets "test/support/secrets-invalid.json" |> File.read!() |> Base.encode64()

  describe "load/2" do

    test "it replaces matching tags with values from secrets" do
      GoogleSecretProvider.MockApiClient
      |> expect(:fetch_secrets, fn _token, _project_id, _secret_id, _version -> {:ok, @valid_secrets} end)

      GoogleSecretProvider.MockAuthToken
      |> expect(:for_scope, fn _scope -> {:ok, "secret-token"} end)

      config = [
        foo: [
          key: "value"
        ],
        application: [
          {:root_level_value_without_tag, 15},
          {:root_level_value_with_tag, {:google_secret, "root_value"}},
          {SomeModule, [
            username: {:google_secret, "username"},
            password: {:google_secret, "password"},
          ]}
        ]
      ]

      replaced_configs = GoogleSecretProvider.load(config, %{project_id: "123456789", secret_id: "app-secret-id"})

      expected = [
        foo: [
          key: "value"
        ],
        application: [
          {:root_level_value_without_tag, 15},
          {:root_level_value_with_tag, "secret-value"},
          {SomeModule, [
            username: "secret-username",
            password: "1234567890",
          ]}
        ]
      ]

      assert replaced_configs == expected
    end

  end
end
