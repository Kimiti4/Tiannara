defmodule Tiannara.Sentinel.Contracts.Anomaly do
  @moduledoc """
  Defines an Anomaly inside the Sentinel runtime.
  """
  defstruct [:id, :type, :severity, :source, :context, :timestamp]

  @type anomaly_type ::
          :type_a_local_process
          | :type_b_ecological
          | :type_c_causal
          | :type_d_semantic
          | :type_e_recursion
          | :type_f_collapse

  @type t :: %__MODULE__{
          id: String.t(),
          type: anomaly_type(),
          severity: Tiannara.Sentinel.Contracts.Severity.t(),
          source: atom() | String.t(),
          context: map(),
          timestamp: integer()
        }
end
