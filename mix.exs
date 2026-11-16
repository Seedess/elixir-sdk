defmodule SeedessSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :seedess_sdk,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: false,
      description: "Official Seedess SDK for Elixir.",
      package: [
        name: "seedess_sdk",
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/Seedess/elixir-sdk",
          "Docs" => "https://seedess.com/docs/"
        },
        files: ~w(lib mix.exs README.md LICENSE)
      ],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:inets, :ssl, :crypto]]
  end

  defp deps do
    [
      # Only for the runnable example server.
      {:plug_cowboy, "~> 2.7", only: :dev}
    ]
  end
end
