defmodule GoogleSecretProvider.MixProject do
  use Mix.Project

  def project do
    [
      app: :google_secret_provider,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:goth, "~> 1.1.0"},
      {:google_api_secret_manager, "~> 0.16"}
    ]
  end
end
