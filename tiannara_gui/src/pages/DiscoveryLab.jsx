import { useState } from "react";
import { apiPost } from "../api/client";

export default function DiscoveryLab() {
  const [question, setQuestion] = useState("How can prosthetic grip stability be improved under fatigue?");
  const [text, setText] = useState(
    "Grip stability depends on damping and stiffness. Higher damping reduces slip risk. Fatigue increases tremor and reduces control precision."
  );
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState("");

  async function handleAnalyze(e) {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const data = await apiPost("/discovery/analyze", {
        question,
        text,
        source: "gui_input",
      });
      setResult(data);
    } catch (err) {
      setError(err.message);
      setResult(null);
    } finally {
      setLoading(false);
    }
  }

  const report = result?.report;
  const claims = report?.claims || [];
  const hypotheses = report?.hypotheses || [];
  const experiments = report?.experiments || [];
  const safetyGate = report?.safety_gate || null;

  return (
    <div className="space-y-6">
      <section>
        <h1 className="text-3xl font-bold text-white">Discovery Lab</h1>
        <p className="mt-2 text-slate-400">
          Ask Tiannara to extract claims, generate hypotheses, and design experiments.
        </p>
      </section>

      <div className="grid gap-6 xl:grid-cols-[420px_1fr]">
        <form
          onSubmit={handleAnalyze}
          className="rounded-2xl border border-slate-800 bg-slate-900 p-5"
        >
          <h2 className="text-lg font-semibold text-white">Research Input</h2>

          <label className="mt-4 block text-sm text-slate-300">Question</label>
          <textarea
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
            rows={3}
            className="mt-2 w-full rounded-xl border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white outline-none focus:border-cyan-500"
          />

          <label className="mt-4 block text-sm text-slate-300">Source text</label>
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            rows={8}
            className="mt-2 w-full rounded-xl border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white outline-none focus:border-cyan-500"
          />

          <button
            type="submit"
            disabled={loading}
            className="mt-4 w-full rounded-xl bg-cyan-500 px-4 py-2 font-medium text-slate-950 transition hover:bg-cyan-400 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? "Analyzing..." : "Run Discovery"}
          </button>

          {error ? (
            <div className="mt-4 rounded-xl border border-rose-800/60 bg-rose-950/20 p-3 text-sm text-rose-300">
              {error}
            </div>
          ) : null}
        </form>

        <div className="space-y-4">
          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
            <h2 className="text-lg font-semibold text-white">Safety Gate</h2>
            {!safetyGate ? (
              <p className="mt-3 text-sm text-slate-400">No result yet.</p>
            ) : (
              <div className="mt-3 space-y-2 text-sm text-slate-300">
                <p>
                  <span className="font-semibold text-white">Approved:</span>{" "}
                  {String(safetyGate.approved)}
                </p>
                <p>
                  <span className="font-semibold text-white">Reason:</span>{" "}
                  {safetyGate.reason}
                </p>
                <p>
                  <span className="font-semibold text-white">Alignment score:</span>{" "}
                  {safetyGate.alignment_score}
                </p>
              </div>
            )}
          </div>

          <div className="grid gap-4 xl:grid-cols-3">
            <Panel title="Claims" items={claims} renderItem={(item) => (
              <div>
                <p className="font-medium text-white">Confidence: {item.confidence}</p>
                <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-slate-300">
                  {(item.claims || []).map((c, idx) => <li key={idx}>{c}</li>)}
                </ul>
              </div>
            )} />

            <Panel title="Hypotheses" items={hypotheses} renderItem={(item) => (
              <div>
                <p className="font-medium text-white">{item.hypothesis}</p>
                <p className="mt-2 text-sm text-slate-300">
                  <span className="font-semibold">Falsifier:</span> {item.falsifier}
                </p>
              </div>
            )} />

            <Panel title="Experiments" items={experiments} renderItem={(item) => (
              <div>
                <p className="font-medium text-white">{item.title}</p>
                <p className="mt-2 text-sm text-slate-300">
                  <span className="font-semibold">Type:</span> {item.type}
                </p>
                <p className="mt-1 text-sm text-slate-300">
                  <span className="font-semibold">Question:</span> {item.question}
                </p>
              </div>
            )} />
          </div>
        </div>
      </div>
    </div>
  );
}

function Panel({ title, items, renderItem }) {
  return (
    <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
      <h2 className="text-lg font-semibold text-white">{title}</h2>
      <div className="mt-4 space-y-3">
        {!items.length ? (
          <p className="text-sm text-slate-400">No items yet.</p>
        ) : (
          items.map((item, idx) => (
            <div key={item.id || idx} className="rounded-xl border border-slate-800 bg-slate-950 p-3">
              {renderItem(item)}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
