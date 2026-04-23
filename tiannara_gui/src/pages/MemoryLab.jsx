import { useState } from "react";

import { apiGet } from "../api/client";

function SectionCard({ title, children }) {
  return (
    <div
      style={{
        background: "#0f172a",
        border: "1px solid #1e293b",
        borderRadius: 16,
        padding: 20,
      }}
    >
      <h3 style={{ margin: 0, marginBottom: 16, fontSize: 18, color: "#e2e8f0" }}>
        {title}
      </h3>
      {children}
    </div>
  );
}

function EmptyState({ text }) {
  return <p style={{ color: "#94a3b8", margin: 0 }}>{text}</p>;
}

export default function MemoryLab() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState(null);

  async function loadMemory() {
    setLoading(true);
    setError("");

    try {
      const data = await apiGet("/memory/all?limit=20");
      setResult(data);
    } catch (err) {
      setError(err.message || "Failed to load memory.");
      setResult(null);
    } finally {
      setLoading(false);
    }
  }

  const reports = result?.discovery_reports || [];
  const experiences = result?.experiences || [];

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 13, color: "#64748b" }}>Tiannara Core</div>
        <h1 style={{ margin: "6px 0 8px", fontSize: 32, color: "#f8fafc" }}>
          Memory Explorer
        </h1>
        <p style={{ margin: 0, color: "#94a3b8", lineHeight: 1.6 }}>
          Inspect persisted discovery reports and autonomous cycle experience records.
        </p>
      </div>

      <button
        type="button"
        onClick={loadMemory}
        disabled={loading}
        style={{
          marginBottom: 20,
          padding: "12px 16px",
          borderRadius: 12,
          border: "none",
          background: loading ? "#334155" : "#0ea5e9",
          color: "#ffffff",
          fontWeight: 700,
          cursor: loading ? "not-allowed" : "pointer",
        }}
      >
        {loading ? "Loading Memory..." : "Load Memory"}
      </button>

      {error ? (
        <div
          style={{
            marginBottom: 20,
            background: "#450a0a",
            border: "1px solid #7f1d1d",
            color: "#fecaca",
            borderRadius: 12,
            padding: 12,
          }}
        >
          {error}
        </div>
      ) : null}

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))",
          gap: 20,
        }}
      >
        <SectionCard title={`Discovery Reports (${reports.length})`}>
          {reports.length === 0 ? (
            <EmptyState text="No discovery reports loaded yet." />
          ) : (
            <div style={{ display: "grid", gap: 12 }}>
              {reports.map((item) => (
                <div
                  key={item.id}
                  style={{
                    padding: 14,
                    borderRadius: 12,
                    background: "#020617",
                    border: "1px solid #1e293b",
                  }}
                >
                  <div style={{ color: "#38bdf8", fontWeight: 700 }}>{item.question}</div>
                  <div style={{ marginTop: 6, color: "#94a3b8", fontSize: 13 }}>
                    Source: {item.source}
                  </div>
                  <div style={{ marginTop: 6, color: "#cbd5e1", fontSize: 14 }}>
                    Tags: {(item.tags || []).join(", ") || "none"}
                  </div>
                </div>
              ))}
            </div>
          )}
        </SectionCard>

        <SectionCard title={`Autonomous Experiences (${experiences.length})`}>
          {experiences.length === 0 ? (
            <EmptyState text="No autonomous experiences stored yet." />
          ) : (
            <div style={{ display: "grid", gap: 12 }}>
              {experiences.map((item) => (
                <div
                  key={item.id}
                  style={{
                    padding: 14,
                    borderRadius: 12,
                    background: "#020617",
                    border: "1px solid #1e293b",
                  }}
                >
                  <div style={{ color: "#f59e0b", fontWeight: 700 }}>{item.question}</div>
                  <div style={{ marginTop: 6, color: "#cbd5e1", fontSize: 14 }}>
                    Score: {item.score}
                  </div>
                  <div style={{ marginTop: 6, color: "#94a3b8", fontSize: 13 }}>
                    Source: {item.source}
                  </div>
                </div>
              ))}
            </div>
          )}
        </SectionCard>

        <SectionCard title="Raw JSON">
          {!result ? (
            <EmptyState text="No memory response yet." />
          ) : (
            <pre
              style={{
                margin: 0,
                whiteSpace: "pre-wrap",
                wordBreak: "break-word",
                color: "#cbd5e1",
                fontSize: 13,
                lineHeight: 1.5,
              }}
            >
              {JSON.stringify(result, null, 2)}
            </pre>
          )}
        </SectionCard>
      </div>
    </div>
  );
}
