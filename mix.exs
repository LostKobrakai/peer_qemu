defmodule Qemu.MixProject do
  use Mix.Project

  @app :qemu
  @version "0.1.0"
  @all_targets [
    :qemu_aarch64
  ]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.18",
      archives: [nerves_bootstrap: "~> 1.13"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [{@app, release()}]
    ]
  end

  def cli do
    [preferred_cli_target: [run: :host, test: :host]]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Qemu.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.10", runtime: false},
      {:shoehorn, "~> 0.9.1"},
      {:ring_logger, "~> 0.11.0"},
      {:toolshed, "~> 0.4.0"},
      {:extrace, "~> 0.5"},

      # Allow Nerves.Runtime on host to support development, testing and CI.
      # See config/host.exs for usage.
      {:nerves_runtime, "~> 0.13.0"},

      # Dependencies for all targets except :host
      {:nerves_pack, "~> 0.7.1", targets: @all_targets},
      {:peer_bridge, github: "fhunleth/peer_bridge"},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      {:nerves_system_qemu_aarch64, "~> 0.2", runtime: false, targets: :qemu_aarch64}
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, &install_peer_bridge/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end

  defp install_peer_bridge(release) do
    peer_bridge_app = release.applications[:peer_bridge]

    bin_dir = Path.join(release.path, "bin")
    File.mkdir_p!(bin_dir)

    # Symlink the versioned peer_bridge binary to a known location for erlinit
    target = Path.join(bin_dir, "peer_bridge")
    source = Path.join(["..", "lib", "peer_bridge-#{peer_bridge_app[:vsn]}", "priv", "peer_bridge"])

    _ = File.rm(target)
    File.ln_s!(source, target)

    release
  end
end
