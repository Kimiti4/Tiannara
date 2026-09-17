defmodule TiannaraOS.Provenance.Environment do
  @moduledoc """
  Environment identity: runtime versions and dependency lock fingerprint so an
  execution record pins the exact environment (deps_lock_hash is the
  load-bearing part, per the minimum model).
  """

  alias TiannaraOS.Provenance.Canon
  alias TiannaraOS.Provenance.Identity

  def build(opts \\ []) do
    backend = Keyword.get(opts, :backend, :os.type() |> elem(0) |> to_string())
    os = Keyword.get(opts, :os, :os.type() |> elem(1) |> to_string())
    otp = Keyword.get(opts, :otp, :erlang.system_info(:otp_release) |> to_string())
    elixir = Keyword.get(opts, :elixir, System.version())
    deps_lock_hash = Keyword.get(opts, :deps_lock_hash, deps_lock_fingerprint())

    fields = %{
      "backend" => backend,
      "os" => os,
      "otp" => otp,
      "elixir" => elixir,
      "deps_lock_hash" => deps_lock_hash
    }

    Identity.object_id("environment", fields)
  end

  defp deps_lock_fingerprint do
    # Contribute any mix.lock bytes if present; else a stable marker.
    case File.read("mix.lock") do
      {:ok, bytes} -> Canon.sha256_bytes(bytes)
      _ -> Canon.sha256_bytes("NO_DEPS")
    end
  end
end