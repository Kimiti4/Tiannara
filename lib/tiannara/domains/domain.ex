defmodule Tiannara.Domains.Domain do
  @moduledoc """
  Represents a domain research lens in Tiannara.
  Also defines the standard behaviour for all Research Domains.
  Domains supply domain-specific knowledge; they must delegate
  computational reasoning to Tiannara.Math.
  """

  @derive Jason.Encoder
  defstruct [:id, :name, :description, :program_ids, :status]

  @type context :: map()
  @type hypothesis :: map()
  @type experiment :: map()
  @type result :: {:ok, term()} | {:error, term()}

  @callback discover(context) :: result()
  @callback evaluate(hypothesis) :: result()
  @callback simulate(hypothesis, context) :: result()
  @callback generate_hypotheses(context) :: result()
  @callback design_experiments(hypothesis) :: result()
  @callback validate(experiment) :: result()
  @callback translate(hypothesis) :: result()
  @callback metrics() :: map()
end
