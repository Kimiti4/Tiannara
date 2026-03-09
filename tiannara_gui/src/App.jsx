import { useEffect, useState } from "react";
import DiscoveryLab from "./pages/DiscoveryLab";

const API_BASE = "/api";

const NAV_ITEMS = [
  "Dashboard",
  "Discovery Lab",
  "Pros Control",
  "Runs & Reports",
  "Memory Explorer",
  "Modules",
  "Settings",
];

function StatCard({ title, value, subtitle, color = "#22c55e" }) {
  return (
    <div
      style={{
        background: "#0f172a",
        border: "1px solid #1e293b",
        borderRadius: 16,
        padding: 20,
        minHeight: 120,
      }}
    >
      <div style={{ fontSize: 14, color: "#94a3b8", marginBottom: 10 }}>{title}</div>
      <div style={{ fontSize: 28, fontWeight: 700, color }}>{value}</div>
      <div style={{ fontSize: 13, color: "#64748b", marginTop: 10 }}>{subtitle}</div>
    </div>
  );
}

function Panel({ title, children }) {
  return (
    <div
      style={{
        background: "#0f172a",
        border: "1px solid #1e293b",
        borderRadius: 16,
        padding: 20,
      }}
    >
      <h3 style={{ margin: 0, marginBottom: 16, fontSize: 18 }}>{title}</h3>
      {children}
    </div>
  );
}

export default function App() {
  const [activePage, setActivePage] = useState("Dashboard");
  const [apiStatus, setApiStatus] = useState("Checking...");
  const [statusColor, setStatusColor] = useState("#f59e0b");
  const [modules, setModules] = useState([]);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadStatus() {
      try {
        const res = await fetch(`${API_BASE}/status`);
        if (!res.ok) throw new Error(`Status request failed: ${res.status}`);
        const data = await res.json();
        setApiStatus(data.status || "ok");
        setStatusColor("#22c55e");
        setError("");
      } catch (err) {
        setApiStatus("Offline");
        setStatusColor("#ef4444");
        setError(String(err.message || err));
      }
    }

    async function loadModules() {
      try {
        const res = await fetch(`${API_BASE}/modules`);
        if (!res.ok) throw new Error(`Modules request failed: ${res.status}`);
        const data = await res.json();
        setModules(Object.keys(data));
      } catch {
        setModules([]);
      }
    }

    loadStatus();
    loadModules();
  }, []);

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "grid",
        gridTemplateColumns: "260px 1fr",
        background: "#020617",
      }}
    >
      <aside
        style={{
          borderRight: "1px solid #1e293b",
          background: "#0b1120",
          padding: 20,
        }}
      >
        <div style={{ marginBottom: 24 }}>
          <h1 style={{ margin: 0, fontSize: 28, color: "#38bdf8" }}>Tiannara</h1>
          <p style={{ marginTop: 8, color: "#94a3b8", fontSize: 14 }}>
            Core Control Interface
          </p>
        </div>

        <div
          style={{
            background: "#082f49",
            border: "1px solid #0c4a6e",
            borderRadius: 14,
            padding: 14,
            marginBottom: 22,
          }}
        >
          <div style={{ fontWeight: 700, marginBottom: 8, color: "#7dd3fc" }}>Mission</div>
          <div style={{ fontSize: 13, color: "#cbd5e1", lineHeight: 1.5 }}>
            Advance humanity, preserve life, stay simulation-first, avoid manipulative design.
          </div>
        </div>

        <nav style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {NAV_ITEMS.map((item) => {
            const active = activePage === item;
            return (
              <button
                key={item}
                onClick={() => setActivePage(item)}
                style={{
                  textAlign: "left",
                  padding: "12px 14px",
                  borderRadius: 12,
                  border: active ? "1px solid #0ea5e9" : "1px solid transparent",
                  background: active ? "#082f49" : "transparent",
                  color: active ? "#7dd3fc" : "#cbd5e1",
                  cursor: "pointer",
                  fontSize: 15,
                }}
              >
                {item}
              </button>
            );
          })}
        </nav>
      </aside>

      <main style={{ display: "flex", flexDirection: "column" }}>
        <header
          style={{
            borderBottom: "1px solid #1e293b",
            background: "#020617",
            padding: "18px 24px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div>
            <div style={{ fontSize: 13, color: "#64748b" }}>Tiannara Core</div>
            <div style={{ fontSize: 24, fontWeight: 700 }}>{activePage}</div>
          </div>

          <div
            style={{
              padding: "10px 14px",
              borderRadius: 999,
              border: `1px solid ${statusColor}`,
              color: statusColor,
              fontWeight: 700,
              fontSize: 14,
            }}
          >
            API: {apiStatus}
          </div>
        </header>

        <section style={{ padding: 24 }}>
          {activePage === "Dashboard" && (
            <>
              {error ? (
                <div
                  style={{
                    marginBottom: 20,
                    background: "#450a0a",
                    border: "1px solid #7f1d1d",
                    color: "#fecaca",
                    borderRadius: 12,
                    padding: 14,
                  }}
                >
                  {error}
                </div>
              ) : null}

              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                  gap: 16,
                  marginBottom: 24,
                }}
              >
                <StatCard
                  title="API Status"
                  value={apiStatus}
                  subtitle="FastAPI backend state"
                  color={statusColor}
                />
                <StatCard
                  title="Loaded Modules"
                  value={modules.length}
                  subtitle={modules.length ? modules.join(", ") : "No modules detected"}
                  color="#38bdf8"
                />
                <StatCard
                  title="Scientific Discovery"
                  value="Ready"
                  subtitle="Claims, hypotheses, experiments"
                  color="#a78bfa"
                />
                <StatCard
                  title="Interaction Policy"
                  value="Non-addictive"
                  subtitle="Mission-aligned interface design"
                  color="#22c55e"
                />
              </div>

              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "2fr 1fr",
                  gap: 16,
                }}
              >
                <Panel title="System Overview">
                  <div style={{ color: "#cbd5e1", lineHeight: 1.7, fontSize: 15 }}>
                    <p>
                      Tiannara is structured as a mission-governed intelligence framework with
                      scientific discovery, safety evaluation, module governance, and future
                      domain-specific expansion.
                    </p>
                    <p>
                      This dashboard will become the control center for Discovery, Pros, Robotics,
                      Defense, Finance, and Med systems.
                    </p>
                  </div>
                </Panel>

                <Panel title="Next Actions">
                  <ul style={{ margin: 0, paddingLeft: 18, color: "#cbd5e1", lineHeight: 1.8 }}>
                    <li>Connect Discovery Lab form</li>
                    <li>Render hypotheses and experiments</li>
                    <li>Add module toggles</li>
                    <li>Add Tiannara Pros controls</li>
                  </ul>
                </Panel>
              </div>
            </>
          )}

          {activePage === "Discovery Lab" && <DiscoveryLab />}

          {activePage !== "Dashboard" && activePage !== "Discovery Lab" && (
            <Panel title={activePage}>
              <p style={{ color: "#cbd5e1", lineHeight: 1.7 }}>
                This page is the next section of the Tiannara GUI. We’ll wire it up step by step.
              </p>
            </Panel>
          )}
        </section>
      </main>
    </div>
  );
}
