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

export default function AutonomousLab() {
  const [activeTab, setActiveTab] = useState("standard"); // Added tab state
  const [question, setQuestion] = useState("Optimize prosthetic grip stability");
  const [text, setText] = useState(
    "Grip stability degrades under fatigue. Higher damping reduces slip but can increase response delay."
  );
  const [populationSize, setPopulationSize] = useState(24);
  const [generations, setGenerations] = useState(12);
  const [workers, setWorkers] = useState(4);
  const [genomeType, setGenomeType] = useState("mixed");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState(null);
  const [autonomousResult, setAutonomousResult] = useState(null); // New state for autonomous scientist
  const [autonomousLoading, setAutonomousLoading] = useState(false); // New loading state

  async function runCycle(event) {
    event.preventDefault();
    setLoading(true);
    setError("");
    setResult(null);

    try {
      const data = await apiPost("/autonomous/cycle", {
        question,
        text,
        source: "autonomous_lab",
        population_size: populationSize,
        generations,
        fitness_function: "grip_stability",
        workers,
        genome_type: genomeType,
      });
      setResult(data);
    } catch (err) {
      setError(err.message || "Failed to run autonomous cycle.");
    } finally {
      setLoading(false);
    }
  }

  // New function for autonomous scientist
  async function runAutonomousScientist(event) {
    event.preventDefault();
    setAutonomousLoading(true);
    setError("");
    setAutonomousResult(null);

    try {
      const data = await apiPost("/autonomous/run", {});
      setAutonomousResult(data);
    } catch (err) {
      setError(err.message || "Failed to run autonomous scientist.");
    } finally {
      setAutonomousLoading(false);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 13, color: "#64748b" }}>Tiannara Core</div>
        <h1 style={{ margin: "6px 0 8px", fontSize: 32, color: "#f8fafc" }}>
          Autonomous Scientist Lab
        </h1>
        <p style={{ margin: 0, color: "#94a3b8", lineHeight: 1.6 }}>
          Run discovery, evolution, simulation, and memory storage in a single cycle.
        </p>
      </div>

      {/* Tab Navigation */}
      <div style={{ marginBottom: 20 }}>
        <button
          onClick={() => setActiveTab("standard")}
          style={{
            marginRight: 10,
            padding: "8px 16px",
            backgroundColor: activeTab === "standard" ? "#0ea5e9" : "#334155",
            color: "#ffffff",
            border: "none",
            borderRadius: 8,
            cursor: "pointer",
          }}
        >
          Standard Autonomous
        </button>
        <button
          onClick={() => setActiveTab("scientist")}
          style={{
            padding: "8px 16px",
            backgroundColor: activeTab === "scientist" ? "#0ea5e9" : "#334155",
            color: "#ffffff",
            border: "none",
            borderRadius: 8,
            cursor: "pointer",
          }}
        >
          Autonomous Scientist
        </button>
      </div>

      {activeTab === "standard" ? (
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
            <h3 style={{ marginTop: 0, marginBottom: 16 }}>Cycle Inputs</h3>

            <form onSubmit={runCycle}>
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
                Context Notes
              </label>
              <textarea
                value={text}
                onChange={(event) => setText(event.target.value)}
                rows={8}
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
                min="6"
                max="200"
                style={inputStyle}
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
                min="1"
                max="200"
                style={inputStyle}
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
                Workers
              </label>
              <input
                type="number"
                value={workers}
                onChange={(event) => setWorkers(Number(event.target.value))}
                min="1"
                max="16"
                style={inputStyle}
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
                Genome Strategy
              </label>
              <select
                value={genomeType}
                onChange={(event) => setGenomeType(event.target.value)}
                style={inputStyle}
              >
                <option value="mixed">Mixed</option>
                <option value="neural">Neural Only</option>
                <option value="graph">Graph Only</option>
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
                {loading ? "Running Autonomous Cycle..." : "Run Autonomous Cycle"}
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
            <SectionCard title="Cycle Summary">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No autonomous result yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 10 }}>
                  <ResultRow label="Score" value={String(result.score)} />
                  <ResultRow label="Experience ID" value={result.experience_id} />
                  <ResultRow label="Mutation Rate" value={String(result.meta?.mutation_rate || "N/A")} />
                  <ResultRow
                    label="Selection Pressure"
                    value={String(result.meta?.selection_pressure || "N/A")}
                  />
                  <ResultRow label="Reward Bias" value={String(result.meta?.reward_bias || "N/A")} />
                  <ResultRow
                    label="Best Candidate"
                    value={JSON.stringify(result.evolution?.best_candidate || {}, null, 2)}
                  />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Phase 5 Telemetry">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No DEAA telemetry yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 10 }}>
                  <ResultRow label="Phase" value={String(result.telemetry?.phase || "N/A")} />
                  <ResultRow
                    label="Execution Backend"
                    value={String(result.telemetry?.execution_backend || "N/A")}
                  />
                  <ResultRow
                    label="Genome Strategy"
                    value={String(result.telemetry?.genome_strategy || "N/A")}
                  />
                  <ResultRow
                    label="Difficulty"
                    value={String(result.telemetry?.difficulty ?? "N/A")}
                  />
                  <ResultRow
                    label="Diversity"
                    value={String(result.telemetry?.diversity ?? "N/A")}
                  />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Memory Intelligence">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No intelligence output yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 10 }}>
                  <ResultRow
                    label="Average Score"
                    value={String(result.intelligence?.avg_score ?? "N/A")}
                  />
                  <ResultRow
                    label="Best Past Score"
                    value={String(result.intelligence?.best_score ?? "N/A")}
                  />
                  <ResultRow
                    label="Suggested Strategy"
                    value={JSON.stringify(result.strategy || {}, null, 2)}
                  />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Adversarial System">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No adversarial telemetry yet.</p>
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
                    label="Difficulty Delta"
                    value={String(result.adversarial?.difficulty_delta ?? "N/A")}
                  />
                  <ResultRow label="Trend" value={formatTrend(result.adversarial?.trend)} />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Distributed Runs">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No distributed telemetry yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 10 }}>
                  <ResultRow
                    label="Workers Used"
                    value={String(result.distributed?.worker_count ?? "N/A")}
                  />
                  <ResultRow
                    label="Average Score"
                    value={String(result.distributed?.avg_score ?? "N/A")}
                  />
                  <ResultRow
                    label="Score Spread"
                    value={String(result.distributed?.score_spread ?? "N/A")}
                  />
                  <ResultRow
                    label="Genome Counts"
                    value={JSON.stringify(result.distributed?.genome_counts || {}, null, 2)}
                  />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Meta Evolution">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No meta-evolution state yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 12 }}>
                  {(result.meta_evolution?.llm_decisions || []).map((entry) => (
                    <div
                      key={entry.worker_id}
                      style={{
                        border: "1px solid #1e293b",
                        borderRadius: 12,
                        padding: 12,
                        background: "#020617",
                      }}
                    >
                      <div style={{ color: "#e2e8f0", fontWeight: 700, marginBottom: 8 }}>
                        Worker {entry.worker_id} - {entry.choice}
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
                        {JSON.stringify(entry.meta, null, 2)}
                      </pre>
                    </div>
                  ))}
                </div>
              )}
            </SectionCard>

            <SectionCard title="Evolution Metrics">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No evolution metrics yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 10 }}>
                  <ResultRow label="Latest" value={String(result.metrics?.latest ?? "N/A")} />
                  <ResultRow label="Delta" value={String(result.metrics?.delta ?? "N/A")} />
                  <ResultRow label="Trend" value={formatTrend(result.metrics?.trend)} />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Simulation">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No simulation output yet.</p>
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
                  {JSON.stringify(result.simulation, null, 2)}
                </pre>
              )}
            </SectionCard>

            <SectionCard title="PROS Feedback">
              {!result ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No PROS feedback yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 10 }}>
                  <ResultRow label="Risk" value={String(result.pros?.risk ?? "N/A")} />
                  <ResultRow
                    label="Failure Reason"
                    value={String(result.pros?.failure_reason || "unknown")}
                  />
                  <ResultRow
                    label="Targets"
                    value={JSON.stringify(result.pros?.targets || {}, null, 2)}
                  />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Leaderboard">
              {!result?.evolution?.leaderboard?.length ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No competition data yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 12 }}>
                  {result.evolution.leaderboard.map((entry) => (
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
                <p style={{ color: "#94a3b8", margin: 0 }}>No API response yet.</p>
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
      ) : (
        /* Autonomous Scientist Tab */
        <div>
          <div
            style={{
              background: "#0f172a",
              border: "1px solid #1e293b",
              borderRadius: 16,
              padding: 20,
              marginBottom: 20,
            }}
          >
            <h3 style={{ marginTop: 0, marginBottom: 16 }}>Autonomous Scientist Controls</h3>
            <form onSubmit={runAutonomousScientist}>
              <button
                type="submit"
                disabled={autonomousLoading}
                style={{
                  padding: "12px 16px",
                  borderRadius: 12,
                  border: "none",
                  background: autonomousLoading ? "#334155" : "#0ea5e9",
                  color: "#ffffff",
                  fontWeight: 700,
                  cursor: autonomousLoading ? "not-allowed" : "pointer",
                }}
              >
                {autonomousLoading ? "Running Autonomous Scientist..." : "Run Autonomous Scientist Cycles"}
              </button>
            </form>
          </div>

          {error && activeTab === "scientist" ? (
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

          <div style={{ display: "grid", gap: 20 }}>
            <SectionCard title="Autonomous Scientist Results">
              {!autonomousResult ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No autonomous scientist results yet.</p>
              ) : (
                <div style={{ display: "grid", gap: 10 }}>
                  <ResultRow 
                    label="Best Results" 
                    value={
                      <pre style={{ margin: 0, color: "#e2e8f0", fontSize: 12 }}>
                        {JSON.stringify(autonomousResult.best || [], null, 2)}
                      </pre>
                    } 
                  />
                  <ResultRow 
                    label="Knowledge Summary" 
                    value={
                      <pre style={{ margin: 0, color: "#e2e8f0", fontSize: 12 }}>
                        {JSON.stringify(autonomousResult.knowledge || {}, null, 2)}
                      </pre>
                    } 
                  />
                </div>
              )}
            </SectionCard>

            <SectionCard title="Autonomous Scientist Raw Output">
              {!autonomousResult ? (
                <p style={{ color: "#94a3b8", margin: 0 }}>No API response yet.</p>
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
                  {JSON.stringify(autonomousResult, null, 2)}
                </pre>
              )}
            </SectionCard>
          </div>
        </div>
      )}
    </div>
  );
}