defmodule Tiannara.Omega.CertificationServer do
  @moduledoc """
  Produces multi-dimensional certificates for validated improvements. Wraps the
  Certification Pipeline. Publishes certificates to the bus for governance.

  AUTHORITY BOUNDARY: certifies. Does NOT deploy. Certification is a necessary
  but not sufficient condition for deployment.

  Constitutional basis: Verification First, "No feature is complete until it is
  validated", Evidence Before Confidence.
  """
  use GenServer

  alias Tiannara.Runtime.EventBus
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Certification.Pipeline, as: CertPipeline

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "Return certificates issued so far (observability)."
  def certificates(server), do: GenServer.call(server, :certificates)

  @doc "Revoke a certificate by ID (governance action)."
  def revoke_certificate(server, cert_id) do
    GenServer.call(server, {:revoke, cert_id})
  end

  @doc "Check if a certificate is currently valid."
  def valid_certificate?(server, cert_id) do
    GenServer.call(server, {:valid?, cert_id})
  end

  @impl true
  def init(opts) do
    {:ok, %{bus: Keyword.fetch!(opts, :bus), certificates: []}}
  end

  @impl true
  def handle_info({:epistemic_event, %EpistemicEvent{type: :experiment_completed} = event}, state) do
    # Honest: without independent verification evidence the certification
    # dimensions are unevaluated. The Certification Pipeline treats an
    # unevaluated CRITICAL dimension as blocking, so the resulting certificate
    # is truthfully NOT CERTIFIED until real evidence exists.
    gate_results = %{
      sandbox_validated: :unevaluated,
      evidence_present: :unevaluated,
      validation_passed: :unevaluated
    }

    evidence = event.evidence_envelope || %{}

    # An experiment-completed event is not certification evidence by itself.
    # Certification requires an explicit real execution result plus observed
    # and independently verified effects. Simulation/planning envelopes remain
    # non-certifying.
    gate_results =
      if certifiable_execution_evidence?(evidence) do
        gate_results
      else
        Map.new(gate_results, fn {id, _value} -> {id, :unevaluated} end)
      end

    certificate = CertPipeline.evaluate(gate_results,
      subsystem: :omega_improvement,
      issuer: "omega-certification-authority",
      version: 1
    )

    EventBus.publish(state.bus, %EpistemicEvent{
      type: :knowledge_updated,
      severity: :medium,
      payload: %{certificate: certificate, for: event.payload},
      confidence: nil,
      uncertainty: 1.0,
      evidence: [evidence],
      evidence_envelope: %{
        evidence_class: :real,
        execution_mode: :real_execution,
        source: :omega_certification_server,
        certification_eligible: certificate.verdict == :certified
      }
    })

    {:noreply, %{state | certificates: [certificate | state.certificates]}}
  end

  def handle_info({:epistemic_event, _event}, state), do: {:noreply, state}

  defp certifiable_execution_evidence?(evidence) when is_map(evidence) do
    Map.get(evidence, :evidence_class) == :real and
      Map.get(evidence, :execution_mode) == :real_execution and
      Map.get(evidence, :real_observation) == true and
      Map.get(evidence, :effect_verified) == true and
      Map.get(evidence, :acl_status) in [:pass, :passed] and
      Map.get(evidence, :oavl_status) in [:pass, :passed]
  end

  defp certifiable_execution_evidence?(_), do: false

  @impl true
  def handle_call(:certificates, _from, state) do
    {:reply, Enum.reverse(state.certificates), state}
  end

  @impl true
  def handle_call({:revoke, cert_id}, _from, state) do
    # Mark certificate as revoked
    updated_certs = Enum.map(state.certificates, fn
      %{id: ^cert_id} = cert -> Map.put(cert, :revoked, true)
      cert -> cert
    end)

    {:reply, :ok, %{state | certificates: updated_certs}}
  end

  @impl true
  def handle_call({:valid?, cert_id}, _from, state) do
    cert_status = Enum.find_value(state.certificates, fn
      %{id: ^cert_id, revoked: true} -> false
      %{id: ^cert_id} -> true
      _ -> nil
    end)

    reply = if cert_status === nil, do: {:error, :not_found}, else: {:ok, cert_status}
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:revoke, cert_id}, _from, state) do
    # Mark certificate as revoked
    updated_certs = Enum.map(state.certificates, fn
      %{id: ^cert_id} = cert -> Map.put(cert, :revoked, true)
      cert -> cert
    end)

    {:reply, :ok, %{state | certificates: updated_certs}}
  end

  @impl true
  def handle_call({:valid?, cert_id}, _from, state) do
    cert_status = Enum.find_value(state.certificates, fn
      %{id: ^cert_id, revoked: true} -> false
      %{id: ^cert_id} -> true
      _ -> nil
    end)

    reply = if cert_status === nil, do: {:error, :not_found}, else: {:ok, cert_status}
    {:reply, reply, state}
  end
end