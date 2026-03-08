export default function Topbar() {
  return (
    <header className="border-b border-slate-800 bg-slate-950/80 px-6 py-4 backdrop-blur">
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-sm text-slate-400">Tiannara Control Interface</p>
          <h2 className="text-lg font-semibold text-white">
            Core Expansion Console
          </h2>
        </div>

        <div className="rounded-full border border-emerald-800 bg-emerald-950/40 px-3 py-1 text-sm text-emerald-300">
          API-ready
        </div>
      </div>
    </header>
  );
}
