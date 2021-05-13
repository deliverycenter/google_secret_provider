defmodule GoogleSecretProviderTest do
  use ExUnit.Case
  doctest GoogleSecretProvider

  import Mox

  alias GoogleSecretProvider.{Exception, MockApiClient, MockAuthToken}

  setup :verify_on_exit!

  @valid_secrets "test/support/secrets-valid.json" |> File.read!() |> Base.encode64()
  @invalid_secrets "test/support/secrets-invalid.json" |> File.read!() |> Base.encode64()
  @project_configs %{project_id: "123456789", secret_id: "app-secret-id"}

  describe "load/2" do

    test "it replaces matching tags with values from secrets" do
      MockApiClient
      |> expect(:fetch_secrets, fn _token, _project_id, _secret_id, _version -> {:ok, @valid_secrets} end)

      MockAuthToken
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

      replaced_configs = GoogleSecretProvider.load(config, @project_configs)

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

    test "raises an error when secrets is not a valid JSON" do
      MockApiClient
      |> expect(:fetch_secrets, fn _token, _project_id, _secret_id, _version -> {:ok, @invalid_secrets} end)

      MockAuthToken
      |> expect(:for_scope, fn _scope -> {:ok, "secret-token"} end)

      assert_raise(Exception, "Error decoding secrets. Make sure your secret is a valid JSON.", fn  ->
        GoogleSecretProvider.load([], @project_configs)
      end)
    end

    test "raises an error when it is not possible to get an auth token" do
      MockAuthToken
      |> expect(:for_scope, fn _scope -> {:error, "some error"} end)

      assert_raise(Exception, "Error fetching token from Goth: \"some error\"", fn  ->
        GoogleSecretProvider.load([], @project_configs)
      end)
    end

    test "raises an error when it is not possible to get secrets from API" do
      MockApiClient
      |> expect(:fetch_secrets, fn _token, _project_id, _secret_id, _version -> {:error, "some error"} end)

      MockAuthToken
      |> expect(:for_scope, fn _scope -> {:ok, "secret-token"} end)

      assert_raise(Exception, "Error fetching secrets from Google API: \"some error\"", fn  ->
        GoogleSecretProvider.load([], @project_configs)
      end)
    end

    test "raises an error when specified JSON key does not exist in secrets" do
      MockApiClient
      |> expect(:fetch_secrets, fn _token, _project_id, _secret_id, _version -> {:ok, @valid_secrets} end)

      MockAuthToken
      |> expect(:for_scope, fn _scope -> {:ok, "secret-token"} end)

      config = [
        foo: [
          bar: {:google_secret, "missing-key"}
        ]
      ]

      assert_raise(Exception, "Could not find key 'missing-key' in JSON secret payload", fn  ->
        GoogleSecretProvider.load(config, @project_configs)
      end)
    end

  end
end
