import { useEffect, useState } from "react";

import { apiGet } from "./api/client";
import AutonomousLab from "./pages/AutonomousLab";
import DiscoveryLab from "./pages/DiscoveryLab";
import EvolutionLab from "./pages/EvolutionLab";
import MemoryLab from "./pages/MemoryLab";
import ModulesPage from "./pages/ModulesPage";
import ProsControl from "./pages/ProsControl";
import RunsPage from "./pages/RunsPage";
import SettingsPage from "./pages/SettingsPage";

const NAV_ITEMS = [
  "Dashboard",
  "Discovery Lab",
  "Evolution Lab",
  "Autonomous Lab",
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

function renderPage(activePage) {
  switch (activePage) {
    case "Discovery Lab":
      return <DiscoveryLab />;
    case "Evolution Lab":
      return <EvolutionLab />;
    case "Autonomous Lab":
      return <AutonomousLab />;
    case "Pros Control":
      return <ProsControl />;
    case "Runs & Reports":
      return <RunsPage />;
    case "Memory Explorer":
      return <MemoryLab />;
    case "Modules":
      return <ModulesPage />;
    case "Settings":
      return <SettingsPage />;
    default:
      return null;
  }
}

export default function App() {
  const [activePage, setActivePage] = useState("Dashboard");
  const [apiStatus, setApiStatus] = useState("Checking...");
  const [statusColor, setStatusColor] = useState("#f59e0b");
  const [modules, setModules] = useState([]);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    async function loadStatus() {
      try {
        const data = await apiGet("/status");
        if (!active) {
          return;
        }
        setApiStatus(data.status || "ok");
        setStatusColor("#22c55e");
        setError("");
      } catch (err) {
        if (!active) {
          return;
        }
        setApiStatus("Offline");
        setStatusColor("#ef4444");
        setError(String(err.message || err));
      }
    }

    async function loadModules() {
      try {
        const data = await apiGet("/modules");
        if (!active) {
          return;
        }
        setModules(Object.keys(data));
      } catch {
        if (!active) {
          return;
        }
        setModules([]);
      }
    }

    loadStatus();
    loadModules();

    return () => {
      active = false;
    };
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
            const isActive = activePage === item;
            return (
              <button
                key={item}
                onClick={() => setActivePage(item)}
                style={{
                  textAlign: "left",
                  padding: "12px 14px",
                  borderRadius: 12,
                  border: isActive ? "1px solid #0ea5e9" : "1px solid transparent",
                  background: isActive ? "#082f49" : "transparent",
                  color: isActive ? "#7dd3fc" : "#cbd5e1",
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
          {activePage === "Dashboard" ? (
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
                  title="Autonomous Cycle"
                  value="Online"
                  subtitle="Discovery -> Evolution -> Simulation -> Memory"
                  color="#f59e0b"
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
                      discovery, evolution, simulation, memory, and prosthetic control layers.
                    </p>
                    <p>
                      Use the labs to run one-off discovery analysis, evolve candidate parameters,
                      or execute a full autonomous cycle that stores its results in memory.
                    </p>
                  </div>
                </Panel>

                <Panel title="Next Actions">
                  <ul style={{ margin: 0, paddingLeft: 18, color: "#cbd5e1", lineHeight: 1.8 }}>
                    <li>Run Discovery Lab on a prosthetic-control question</li>
                    <li>Compare Evolution Lab candidate histories</li>
                    <li>Execute Autonomous Lab and inspect saved memory</li>
                    <li>Review enabled modules and governance metadata</li>
                  </ul>
                </Panel>
              </div>
            </>
          ) : (
            renderPage(activePage)
          )}
        </section>
      </main>
    </div>
  );
}
