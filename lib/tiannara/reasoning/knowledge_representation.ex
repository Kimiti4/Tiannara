defmodule Tiannara.Reasoning.KnowledgeRepresentation do
  @moduledoc "Ontology management, semantic triples, and graph embeddings."

  def assert_fact(subject, predicate, object, confidence) do
    {:ok, %{subject: subject, predicate: predicate, object: object, confidence: confidence}}
  end

  def query_ontology(_domain, _context), do: {:ok, []}
end
