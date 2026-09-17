defmodule TiannaraWeb.RouterTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  @endpoint TiannaraWeb.Endpoint

  setup do
    Application.ensure_all_started(:tiannara)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  test "GET /api/health returns operational health payload", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert conn.status == 200
    assert %{"health" => "operational"} = Jason.decode!(conn.resp_body)
  end

  test "GET /api/v1/health returns operational health payload", %{conn: conn} do
    conn = get(conn, "/api/v1/health")
    assert conn.status == 200
    assert %{"health" => "operational"} = Jason.decode!(conn.resp_body)
  end

  test "GET /api/v1/runtime/boot returns boot phases", %{conn: conn} do
    conn = get(conn, "/api/v1/runtime/boot")
    assert conn.status == 200
    assert %{"status" => "ready"} = Jason.decode!(conn.resp_body)
  end

  test "GET /api/runtime/boot returns boot phases", %{conn: conn} do
    conn = get(conn, "/api/runtime/boot")
    assert conn.status == 200
    assert %{"status" => "ready"} = Jason.decode!(conn.resp_body)
  end

  test "GET /api/v1/runtime/status returns service statuses", %{conn: conn} do
    conn = get(conn, "/api/v1/runtime/status")
    assert conn.status == 200
    assert %{"services" => services} = Jason.decode!(conn.resp_body)
    assert Enum.any?(services, &(&1["name"] == "BEAM"))
  end

  test "POST /api/v1/interaction accepts room and message", %{conn: conn} do
    conn = post(conn, "/api/v1/interaction", %{room: "general", message: "hello"})
    assert conn.status == 200
    assert %{"data" => data} = Jason.decode!(conn.resp_body)
    assert data["message"] =~ "hello"
  end

  test "POST /api/crav/alpha_launch/preflight returns checklist", %{conn: conn} do
    conn = post(conn, "/api/crav/alpha_launch/preflight", %{})
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert Map.has_key?(body, "crav_ready")
    assert Map.has_key?(body, "runtime_census")
  end

  test "POST /api/v1/crav/alpha_launch/preflight returns checklist", %{conn: conn} do
    conn = post(conn, "/api/v1/crav/alpha_launch/preflight", %{})
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert Map.has_key?(body, "crav_ready")
    assert Map.has_key?(body, "runtime_census")
  end

  test "GET /api/v1/runtime/snapshot returns in-process runtime snapshot", %{conn: conn} do
    conn = get(conn, "/api/v1/runtime/snapshot")
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["memory_mb"] > 0
    assert body["process_count"] > 0
    assert is_boolean(body["all_healthy"])
  end

  test "GET /api/v1/discovery/snapshot returns discovery snapshot", %{conn: conn} do
    conn = get(conn, "/api/v1/discovery/snapshot")
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert is_boolean(body["scheduler_alive"])
    assert Map.has_key?(body, "discovery_cycles")
    assert Map.has_key?(body, "knowledge_entities")
  end

  test "GET /api/v1/discovery/pipeline returns pipeline snapshot", %{conn: conn} do
    conn = get(conn, "/api/v1/discovery/pipeline")
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["ok"] == true
    assert map_size(body["pipeline"]["stages"]) == 9
    assert is_list(body["pipeline"]["uninstrumented"])
  end

  test "GET /api/v1/discovery/stall returns first stall", %{conn: conn} do
    conn = get(conn, "/api/v1/discovery/stall")
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["ok"] == true
    assert body["stall"] == nil or Map.has_key?(body["stall"], "stage")
  end

  test "POST /api/v1/discovery/seed seeds epistemic pressure", %{conn: conn} do
    conn = post(conn, "/api/v1/discovery/seed", %{})
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["ok"] == true
    assert body["manifest"]["entities_created"] == 4
  end
end
