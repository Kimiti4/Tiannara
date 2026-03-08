import { useEffect, useState } from "react";
import { apiGet } from "../api/client";
import StatusCard from "../components/cards/StatusCard";

export default function Dashboard() {
  const [status, setStatus] = useState("Checking...");
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    async function loadStatus() {
      try {
        const data = await apiGet("/status");
        if (!active) return;
        setStatus(data.status || "ok");
        setError("");
      } catch (err) {
        if (!active) return;
        setStatus("offline");
        setError(err.message);
      }
    }

    loadStatus();
    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="space-y-6">
      <section>
        <h1 className="text-3xl font-bold text-white">Dashboard</h1>
        <p className="mt-2 text-slate-400">
          Overview of Tiannara Core status and mission systems.
        </p>
      </section>

      {error ? (
        <div className="rounded-2xl border border-rose-800/60 bg-rose-950/20 p-4 text-rose-300">
          API connection error: {error}
        </div>
      ) : null}

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatusCard
          title="API Status"
          value={status}
          subtitle="FastAPI backend"
          tone={status === "ok" ? "success" : "warning"}
        />
        <StatusCard
          title="Mission Mode"
          value="Life-first"
          subtitle="Human, plant, animal preservation"
          tone="info"
        />
        <StatusCard
          title="Reasoning Policy"
          value="Simulation-first"
          subtitle="Research before real-world action"
          tone="info"
        />
        <StatusCard
          title="Interaction Style"
          value="Non-addictive"
          subtitle="No manipulative design loops"
          tone="success"
        />
      </section>

      <section className="grid gap-4 xl:grid-cols-2">
        <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
          <h2 className="text-lg font-semibold text-white">What this GUI will control</h2>
          <ul className="mt-4 space-y-2 text-sm text-slate-300">
            <li>• Scientific Discovery Engine</li>
            <li>• Tiannara Pros runs and reports</li>
            <li>• Module enable/disable state</li>
            <li>• Memory and experiment inspection</li>
          </ul>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
          <h2 className="text-lg font-semibold text-white">Week 1 GUI milestone</h2>
          <ul className="mt-4 space-y-2 text-sm text-slate-300">
            <li>• Dashboard</li>
            <li>• Discovery Lab form + results</li>
            <li>• Modules page</li>
            <li>• FastAPI integration</li>
          </ul>
        </div>
      </section>
    </div>
  );
}
