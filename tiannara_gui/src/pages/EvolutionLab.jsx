import { useState } from "react";

import { apiPost } from "../api/client";

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

function ResultRow({ label, value }) {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "160px 1fr",
        gap: 12,
        alignItems: "start",
      }}
    >
      <div style={{ color: "#94a3b8", fontWeight: 700 }}>{label}</div>
      <div style={{ color: "#e2e8f0", lineHeight: 1.6 }}>{value}</div>
    </div>
  );
}

const inputStyle = {
  width: "100%",
  padding: "12px 14px",
  borderRadius: 12,
  border: "1px solid #334155",
  background: "#020617",
  color: "#e2e8f0",
  outline: "none",
};

const textareaStyle = {
  ...inputStyle,
  resize: "vertical",
  fontFamily: "inherit",
};

function formatTrend(values) {
  if (!values?.length) {
    return "N/A";
  }
  return values.join(" -> ");
}

export default function EvolutionLab() {
  const [question, setQuestion] = useState("Optimize prosthetic grip stability");
  const [populationSize, setPopulationSize] = useState(24);
  const [generations, setGenerations] = useState(12);
  const [fitnessFunction, setFitnessFunction] = useState("grip_stability");
  const [genomeType, setGenomeType] = useState("neural");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState(null);

  async function handleEvolve(event) {
    event.preventDefault();
    setLoading(true);
    setError("");
    setResult(null);

    try {
      const data = await apiPost("/evolution/run", {
        question,
        population_size: populationSize,
        generations,
        fitness_function: fitnessFunction,
        genome_type: genomeType,
      });
      setResult(data);
    } catch (err) {
      setError(err.message || "Failed to run evolution.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 13, color: "#64748b" }}>Tiannara Core</div>
        <h1 style={{ margin: "6px 0 8px", fontSize: 32, color: "#f8fafc" }}>
          Evolution Lab
        </h1>
        <p style={{ margin: 0, color: "#94a3b8", lineHeight: 1.6 }}>
          Run evolutionary search to improve prosthetic control parameters.
        </p>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "minmax(320px, 420px) 1fr",
          gap: 20,
          alignItems: "start",
        }}
      >
        <div
          style={{
            background: "#0f172a",
            border: "1px solid #1e293b",
            borderRadius: 16,
            padding: 20,
            position: "sticky",
            top: 24,
          }}
        >
          <h3 style={{ marginTop: 0, marginBottom: 16 }}>Evolution Parameters</h3>

          <form onSubmit={handleEvolve}>
            <label
              style={{ display: "block", fontSize: 14, marginBottom: 8, color: "#cbd5e1" }}
            >
              Optimization Goal
            </label>
            <textarea
              value={question}
              onChange={(event) => setQuestion(event.target.value)}
              rows={4}
              style={textareaStyle}
            />

            <label
              style={{
                display: "block",
                fontSize: 14,
                marginTop: 16,
                marginBottom: 8,
                color: "#cbd5e1",
              }}
            >
              Population Size
            </label>
            <input
              type="number"
              value={populationSize}
              onChange={(event) => setPopulationSize(Number(event.target.value))}
              style={inputStyle}
              min="6"
              max="200"
            />

            <label
              style={{
                display: "block",
                fontSize: 14,
                marginTop: 16,
                marginBottom: 8,
                color: "#cbd5e1",
              }}
            >
              Generations
            </label>
            <input
              type="number"
              value={generations}
              onChange={(event) => setGenerations(Number(event.target.value))}
              style={inputStyle}
              min="1"
              max="200"
            />

            <label
              style={{
                display: "block",
                fontSize: 14,
                marginTop: 16,
                marginBottom: 8,
                color: "#cbd5e1",
              }}
            >
              Fitness Function
            </label>
            <select
              value={fitnessFunction}
              onChange={(event) => setFitnessFunction(event.target.value)}
              style={inputStyle}
            >
              <option value="grip_stability">Grip Stability</option>
              <option value="maximize_accuracy">Maximize Accuracy</option>
              <option value="optimize_efficiency">Optimize Efficiency</option>
            </select>

            <label
              style={{
                display: "block",
                fontSize: 14,
                marginTop: 16,
                marginBottom: 8,
                color: "#cbd5e1",
              }}
            >
              Genome Type
            </label>
            <select
              value={genomeType}
              onChange={(event) => setGenomeType(event.target.value)}
              style={inputStyle}
            >
              <option value="neural">Neural Genome</option>
              <option value="graph">Graph Genome</option>
            </select>

            <button
              type="submit"
              disabled={loading}
              style={{
                marginTop: 18,
                width: "100%",
                padding: "12px 16px",
                borderRadius: 12,
                border: "none",
                background: loading ? "#334155" : "#0ea5e9",
                color: "#ffffff",
                fontWeight: 700,
                cursor: loading ? "not-allowed" : "pointer",
              }}
            >
              {loading ? "Evolving..." : "Run Evolution"}
            </button>
          </form>

          {error ? (
            <div
              style={{
                marginTop: 16,
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
        </div>

        <div style={{ display: "grid", gap: 20 }}>
          <SectionCard title="Evolution Results">
            {!result ? (
              <EmptyState text="No evolution result yet." />
            ) : (
              <div style={{ display: "grid", gap: 10 }}>
                <ResultRow label="Best Fitness" value={String(result.best_fitness || "N/A")} />
                <ResultRow label="Generations Run" value={String(result.generations_run || "N/A")} />
                <ResultRow label="Converged" value={result.converged ? "Yes" : "No"} />
                <ResultRow label="Genome Type" value={String(result.genome_type || "N/A")} />
                <ResultRow label="Trend" value={formatTrend(result.history)} />
                <ResultRow
                  label="Best Candidate"
                  value={JSON.stringify(result.best_candidate || {}, null, 2)}
                />
              </div>
            )}
          </SectionCard>

          <SectionCard title="Adversarial Telemetry">
            {!result ? (
              <EmptyState text="No adversarial telemetry yet." />
            ) : (
              <div style={{ display: "grid", gap: 10 }}>
                <ResultRow
                  label="Difficulty Start"
                  value={String(result.adversarial?.difficulty_start ?? "N/A")}
                />
                <ResultRow
                  label="Difficulty End"
                  value={String(result.adversarial?.difficulty_end ?? "N/A")}
                />
                <ResultRow
                  label="Difficulty Trend"
                  value={formatTrend(result.adversarial?.history)}
                />
              </div>
            )}
          </SectionCard>

          <SectionCard title="Leaderboard">
            {!result?.leaderboard?.length ? (
              <EmptyState text="No leaderboard data yet." />
            ) : (
              <div style={{ display: "grid", gap: 12 }}>
                {result.leaderboard.map((entry) => (
                  <div
                    key={`${entry.rank}-${entry.generation}`}
                    style={{
                      border: "1px solid #1e293b",
                      borderRadius: 12,
                      padding: 12,
                      background: "#020617",
                    }}
                  >
                    <div style={{ color: "#e2e8f0", fontWeight: 700, marginBottom: 8 }}>
                      Rank {entry.rank} - Fitness {entry.fitness}
                    </div>
                    <pre
                      style={{
                        margin: 0,
                        whiteSpace: "pre-wrap",
                        wordBreak: "break-word",
                        color: "#94a3b8",
                        fontSize: 12,
                        lineHeight: 1.5,
                      }}
                    >
                      {JSON.stringify(entry.candidate, null, 2)}
                    </pre>
                  </div>
                ))}
              </div>
            )}
          </SectionCard>

          <SectionCard title="Raw JSON">
            {!result ? (
              <EmptyState text="No API response yet." />
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
    </div>
  );
}
