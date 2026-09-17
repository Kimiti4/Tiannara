defmodule TiannaraOS.Provenance.Source do
  @moduledoc """
  Source identity: repository, commit, tree, optional dirty fingerprint,
  and the source manifest hash over the explicitly loaded source file list.

  Fixes: wrong_source_commit, T0-style snapshot ambiguity (code committed long
  after execution), zip-bomb attribution. Hash is over the canonical bytes of
  the fields below; nothing is inferred from pathnames.
  """

  alias TiannaraOS.Provenance.Canon
  alias TiannaraOS.Provenance.Identity

  @doc "Build a source identity from captured git state + loaded file list."
  def build(opts) do
    repo = Keyword.fetch!(opts, :repository)
    commit = Keyword.fetch!(opts, :commit)
    tree = Keyword.fetch!(opts, :tree)
    dirty_fingerprint = Keyword.get(opts, :dirty_fingerprint)
    source_files = Keyword.get(opts, :source_files, [])

    fields = %{
      "repository" => repo,
      "commit" => commit,
      "tree" => tree,
      "dirty_fingerprint" => dirty_fingerprint,
      "source_manifest_hash" => source_manifest_hash(source_files)
    }

    Identity.object_id("source", fields)
  end

  defp source_manifest_hash([]), do: nil

  defp source_manifest_hash(files) do
    entries =
      files
      |> Enum.sort()
      |> Enum.map(fn {path, content} -> %{"path" => path, "sha256" => Canon.sha256_bytes(content)} end)

    Canon.sha256(%{"source_files" => entries})
  end

  @doc """
  Capture source identity from the current working directory (must be inside a
  git repo). Pure read-only: rev-parse and status --porcelain, never a write.
  """
  def capture(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    git = Keyword.get(opts, :git, "git")

    {commit, 0} = System.cmd(git, ["rev-parse", "HEAD"], cd: cwd)
    {tree, 0} = System.cmd(git, ["rev-parse", "HEAD^{tree}"], cd: cwd)
    {remote, _} = System.cmd(git, ["config", "--get", "remote.origin.url"], cd: cwd)

    case System.cmd(git, ["status", "--porcelain"], cd: cwd) do
      {out, 0} ->
        fp = if out == "", do: nil, else: hash_porcelain(out)

        build(
          repository: String.trim(remote == "" && "local" || remote),
          commit: String.trim(commit),
          tree: String.trim(tree),
          dirty_fingerprint: fp,
          source_files: Keyword.get(opts, :source_files, [])
        )

      _ ->
        build(
          repository: String.trim(remote == "" && "local" || remote),
          commit: String.trim(commit),
          tree: String.trim(tree),
          dirty_fingerprint: nil,
          source_files: Keyword.get(opts, :source_files, [])
        )
    end
  end

  defp hash_porcelain(porcelain) do
    Canon.sha256_bytes(porcelain)
  end
end