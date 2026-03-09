import { useState } from "react";

const API_BASE = "/api";

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

export default function DiscoveryLab() {
  const [question, setQuestion] = useState(
    "How can prosthetic grip stability be improved under fatigue?"
  );
  const [text, setText] = useState(
    "Grip stability depends on damping and stiffness. Higher damping reduces slip risk. Fatigue increases tremor and reduces control precision."
  );
  const [source, setSource] = useState("gui_input");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState(null);

  async function handleAnalyze(e) {
    e.preventDefault();
    setLoading(true);
    setError("");
    setResult(null);

    try {
      const res = await fetch(`${API_BASE}/discovery/analyze`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          question,
          text,
          source,
        }),
      });

      if (!res.ok) {
        const msg = await res.text();
        throw new Error(msg || `Request failed with status ${res.status}`);
      }

      const data = await res.json();
      setResult(data);
    } catch (err) {
      setError(err.message || "Failed to run discovery analysis.");
    } finally {
      setLoading(false);
    }
  }

  const report = result?.report || null;
  const safety = report?.safety_gate || null;
  const claims = report?.claims || [];
  const hypotheses = report?.hypotheses || [];
  const experiments = report?.experiments || [];

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 13, color: "#64748b" }}>Tiannara Core</div>
        <h1 style={{ margin: "6px 0 8px", fontSize: 32, color: "#f8fafc" }}>
          Discovery Lab
        </h1>
        <p style={{ margin: 0, color: "#94a3b8", lineHeight: 1.6 }}>
          Ask a research question, provide source text, and let Tiannara generate
          claims, hypotheses, experiment ideas, and a safety review.
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
        {/* Left: Input form */}
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
          <h3 style={{ marginTop: 0, marginBottom: 16 }}>Research Input</h3>

          <form onSubmit={handleAnalyze}>
            <label
              style={{ display: "block", fontSize: 14, marginBottom: 8, color: "#cbd5e1" }}
            >
              Scientific Question
            </label>
            <textarea
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              rows={4}
              style={textareaStyle}
              placeholder="Enter the research question..."
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
              Source Text
            </label>
            <textarea
              value={text}
              onChange={(e) => setText(e.target.value)}
              rows={10}
              style={textareaStyle}
              placeholder="Paste notes, abstracts, ideas, or observations..."
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
              Source Label
            </label>
            <input
              value={source}
              onChange={(e) => setSource(e.target.value)}
              style={inputStyle}
              placeholder="e.g. gui_input"
            />

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
              {loading ? "Running Discovery..." : "Run Discovery"}
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

        {/* Right: Results */}
        <div style={{ display: "grid", gap: 20 }}>
          <SectionCard title="Safety Gate">
            {!safety ? (
              <EmptyState text="No discovery result yet." />
            ) : (
              <div style={{ display: "grid", gap: 10 }}>
                <ResultRow label="Approved" value={String(safety.approved)} />
                <ResultRow label="Reason" value={safety.reason} />
                <ResultRow
                  label="Alignment Score"
                  value={String(safety.alignment_score)}
                />
                <ResultRow
                  label="Suggestions"
                  value={safety.suggestions || "None"}
                />
              </div>
            )}
          </SectionCard>

          <SectionCard title={`Claims (${claims.length})`}>
            {claims.length === 0 ? (
              <EmptyState text="No claims yet." />
            ) : (
              <div style={{ display: "grid", gap: 14 }}>
                {claims.map((item, idx) => (
                  <div
                    key={item.id || idx}
                    style={{
                      padding: 14,
                      borderRadius: 12,
                      background: "#020617",
                      border: "1px solid #1e293b",
                    }}
                  >
                    <div style={{ color: "#38bdf8", fontWeight: 700, marginBottom: 8 }}>
                      Confidence: {item.confidence}
                    </div>

                    <div style={{ marginBottom: 10 }}>
                      <div style={miniTitleStyle}>Claim Sentences</div>
                      {(item.claims || []).length ? (
                        <ul style={listStyle}>
                          {item.claims.map((c, i) => (
                            <li key={i}>{c}</li>
                          ))}
                        </ul>
                      ) : (
                        <EmptyState text="No claim sentences extracted." />
                      )}
                    </div>

                    <div style={{ marginBottom: 10 }}>
                      <div style={miniTitleStyle}>Entity Hints</div>
                      {(item.entities_hint || []).length ? (
                        <div style={tagWrapStyle}>
                          {item.entities_hint.map((ent, i) => (
                            <span key={i} style={tagStyle}>
                              {ent}
                            </span>
                          ))}
                        </div>
                      ) : (
                        <EmptyState text="No entities extracted." />
                      )}
                    </div>

                    <div>
                      <div style={miniTitleStyle}>Numbers</div>
                      {(item.numbers || []).length ? (
                        <div style={tagWrapStyle}>
                          {item.numbers.map((n, i) => (
                            <span key={i} style={tagStyle}>
                              {n.value}
                              {n.unit || ""}
                            </span>
                          ))}
                        </div>
                      ) : (
                        <EmptyState text="No numbers extracted." />
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </SectionCard>

          <SectionCard title={`Hypotheses (${hypotheses.length})`}>
            {hypotheses.length === 0 ? (
              <EmptyState text="No hypotheses yet." />
            ) : (
              <div style={{ display: "grid", gap: 14 }}>
                {hypotheses.map((item, idx) => (
                  <div
                    key={item.id || idx}
                    style={{
                      padding: 14,
                      borderRadius: 12,
                      background: "#020617",
                      border: "1px solid #1e293b",
                    }}
                  >
                    <div style={{ color: "#a78bfa", fontWeight: 700, marginBottom: 8 }}>
                      Hypothesis
                    </div>
                    <p style={{ marginTop: 0, color: "#e2e8f0", lineHeight: 1.6 }}>
                      {item.hypothesis}
                    </p>
                    <div style={{ color: "#94a3b8", fontSize: 14 }}>
                      <strong>Falsifier:</strong> {item.falsifier}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </SectionCard>

          <SectionCard title={`Experiments (${experiments.length})`}>
            {experiments.length === 0 ? (
              <EmptyState text="No experiments yet." />
            ) : (
              <div style={{ display: "grid", gap: 14 }}>
                {experiments.map((item, idx) => (
                  <div
                    key={item.id || idx}
                    style={{
                      padding: 14,
                      borderRadius: 12,
                      background: "#020617",
                      border: "1px solid #1e293b",
                    }}
                  >
                    <div style={{ color: "#22c55e", fontWeight: 700, marginBottom: 8 }}>
                      {item.title}
                    </div>
                    <p style={{ color: "#cbd5e1", marginTop: 0, lineHeight: 1.6 }}>
                      <strong>Type:</strong> {item.type}
                    </p>

                    <div style={{ marginBottom: 10 }}>
                      <div style={miniTitleStyle}>Measurements</div>
                      <ul style={listStyle}>
                        {(item.measurements || []).map((m, i) => (
                          <li key={i}>{m}</li>
                        ))}
                      </ul>
                    </div>

                    <div style={{ marginBottom: 10 }}>
                      <div style={miniTitleStyle}>Acceptance Criteria</div>
                      <ul style={listStyle}>
                        {(item.acceptance_criteria || []).map((m, i) => (
                          <li key={i}>{m}</li>
                        ))}
                      </ul>
                    </div>

                    <div>
                      <div style={miniTitleStyle}>Risks and Mitigation</div>
                      <ul style={listStyle}>
                        {(item.risks_and_mitigation || []).map((m, i) => (
                          <li key={i}>{m}</li>
                        ))}
                      </ul>
                    </div>
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

const miniTitleStyle = {
  color: "#94a3b8",
  fontSize: 13,
  fontWeight: 700,
  marginBottom: 6,
};

const listStyle = {
  margin: 0,
  paddingLeft: 18,
  color: "#e2e8f0",
  lineHeight: 1.6,
};

const tagWrapStyle = {
  display: "flex",
  gap: 8,
  flexWrap: "wrap",
};

const tagStyle = {
  background: "#082f49",
  border: "1px solid #0c4a6e",
  color: "#7dd3fc",
  padding: "4px 10px",
  borderRadius: 999,
  fontSize: 12,
};
