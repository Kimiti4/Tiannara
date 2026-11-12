defmodule ObservatoryApiWeb.StatusControllerTest do
  @moduledoc """
  Pins the epistemic-status contract of the status API.

  The status endpoints used to serve placeholder constants and randomly
  generated "resource" numbers as if they were measurements of the running
  system. A consumer could not tell a placeholder from an observation.

  These tests require that every fabricated payload carries an explicit
  `epistemic_status` of "simulated", and that the health endpoint reports
  *observed* process liveness rather than a constant.
  """
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Plug.Conn

  @endpoint ObservatoryApiWeb.Endpoint

  @sections ~w(section_discovery section_worlds section_observatories section_agents
               section_services section_monitoring section_logs section_security
               section_cluster section_storage section_performance)

  defp call(fun) do
    conn = Phoenix.ConnTest.build_conn() |> Plug.Test.init_test_session(%{})

    apply(ObservatoryApiWeb.StatusController, fun, [conn, %{}])
  end

  defp payload(fun) do
    conn = call(fun)
    assert conn.status == 200
    Jason.decode!(conn.resp_body)
  end

  test "every placeholder section is marked simulated, not observed" do
    for section <- @sections do
      body = payload(String.to_existing_atom(section))

      assert body["epistemic_status"] == "simulated",
             "#{section} does not mark its payload as simulated"

      assert body["source"] == "placeholder"
      assert is_binary(body["note"])

      for item <- body["data"] do
        assert item["epistemic_status"] == "simulated",
               "#{section} returns an unmarked item"
      end
    end
  end

  test "the resource endpoint is marked simulated rather than presented as a measurement" do
    body = payload(:resources)

    assert body["epistemic_status"] == "simulated"
    assert body["source"] == "placeholder"
    assert Map.has_key?(body, "cpu")
  end

  test "the experiments endpoint is marked simulated" do
    body = payload(:experiments)

    assert body["epistemic_status"] == "simulated"
    assert is_list(body["data"])
  end

  test "the health endpoint reports observed liveness for each subsystem" do
    body = payload(:index)

    subsystems = body["subsystems"]
    assert is_map(subsystems)
    assert map_size(subsystems) > 0

    for {name, status} <- subsystems do
      assert status["epistemic_status"] == "observed",
             "#{name} does not report an observed status"

      assert status["status"] in ["operational", "unknown"],
             "#{name} reports an unrecognised status: #{inspect(status["status"])}"

      assert status["last_checked"]
    end
  end

  test "the challenge run endpoint marks its fabricated results as simulated" do
    body = payload(:challenges_run)

    assert body["epistemic_status"] == "simulated"

    for {_name, result} <- body["results"] do
      assert result["epistemic_status"] == "simulated"
    end
  end
end
