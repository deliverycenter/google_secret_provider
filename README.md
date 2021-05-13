# GoogleSecretProvider

Config provider for fetching sensitive configs from [Google Secret Manager](https://cloud.google.com/secret-manager). 
It works by replacing the specified configs with values from the secrets when booting the application.

> This implementation is inspired by [GCP Secret Provider
](https://github.com/Adzz/gcp_secret_provider). The main difference is that here we assume all secret data 
for one application is stored in one secret, as JSON. If that's not suitable for your use-case, we recommend checking 
the original lib instead.

## Installation

The package can be installed by adding `google_secret_provider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:google_secret_provider, "~> 0.1.0"}
  ]
end
```

Then, in the releases config on your `mix.exs` file:

```elixir
def project() do
  [
    releases: [
      prod: [
        config_providers: [
          {GoogleSecretProvider, %{project_id: "gcp-project-id", secret_id: "your-secret-id"}}
        ]
      ]
    ]
  ]
end
```

## Example

To actually use the values from your secret, in your environment config files you should use the tuple 
`{:google_secret, "some-key"}` to indicate that it should be replaced with the value of the key `some-key` in the 
JSON secret. **The key must exist in the secret.** 

For example:

```elixir
config :my_app, MyApp.Repo,
  username: {:google_secret, "db_username"},
  password: {:google_secret, "db_password"},
  database: {:google_secret, "db_database"}
```

With the secret

```json
{
  "db_username": "my_app",
  "db_password": "12345678",
  "db_database": "my_app_db"
}
```

Would result in

```elixir
config :my_app, MyApp.Repo,
  username: "my_app",
  password: "12345678",
  database: "my_app_db"
```

## Authentication

This library uses [Goth](https://github.com/peburrows/goth) to authenticate the request to the Google Secrets API. You 
can either supply a service accounts or, if you're running on GCP, your instance should already be authenticated. 