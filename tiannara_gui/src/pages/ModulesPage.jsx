import { useEffect, useState } from "react";
import { apiGet } from "../api/client";

export default function ModulesPage() {
  const [modules, setModules] = useState({});
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    async function loadModules() {
      try {
        const data = await apiGet("/modules");
        if (!active) return;
        setModules(data);
      } catch (err) {
        if (!active) return;
        setError(err.message);
      }
    }

    loadModules();
    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="space-y-6">
      <section>
        <h1 className="text-3xl font-bold text-white">Modules</h1>
        <p className="mt-2 text-slate-400">
          View enabled Tiannara modules and their governance metadata.
        </p>
      </section>

      {error ? (
        <div className="rounded-2xl border border-rose-800/60 bg-rose-950/20 p-4 text-rose-300">
          {error}
        </div>
      ) : null}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {Object.keys(modules).length === 0 ? (
          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5 text-slate-400">
            No modules loaded yet.
          </div>
        ) : (
          Object.entries(modules).map(([name, mod]) => (
            <div key={name} className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-lg font-semibold text-white">{name}</h2>
                  <p className="mt-1 text-sm text-slate-400">
                    {mod.manifest?.description || "No description"}
                  </p>
                </div>
                <span
                  className={`rounded-full px-3 py-1 text-xs font-medium ${
                    mod.enabled
                      ? "bg-emerald-950/40 text-emerald-300"
                      : "bg-slate-800 text-slate-400"
                  }`}
                >
                  {mod.enabled ? "Enabled" : "Disabled"}
                </span>
              </div>

              <div className="mt-4 space-y-2 text-sm text-slate-300">
                <p><span className="font-semibold text-white">Version:</span> {mod.manifest?.version}</p>
                <p><span className="font-semibold text-white">Risk tier:</span> {mod.manifest?.risk_tier}</p>
                <p><span className="font-semibold text-white">Permissions:</span> {(mod.manifest?.permissions || []).join(", ") || "none"}</p>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
