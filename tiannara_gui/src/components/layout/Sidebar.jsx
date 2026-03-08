import { NavLink } from "react-router-dom";

const links = [
  { to: "/", label: "Dashboard" },
  { to: "/discovery", label: "Discovery Lab" },
  { to: "/modules", label: "Modules" },
  { to: "/pros", label: "Pros Control" },
  { to: "/runs", label: "Runs & Reports" },
  { to: "/memory", label: "Memory Explorer" },
  { to: "/settings", label: "Settings" },
];

export default function Sidebar() {
  return (
    <aside className="hidden w-64 shrink-0 border-r border-slate-800 bg-slate-900 md:block">
      <div className="border-b border-slate-800 px-5 py-4">
        <h1 className="text-xl font-bold tracking-wide text-cyan-400">Tiannara</h1>
        <p className="mt-1 text-xs text-slate-400">
          Progress humanity. Preserve life.
        </p>
      </div>

      <nav className="p-3">
        <div className="mb-3 rounded-xl border border-cyan-900/40 bg-cyan-950/20 p-3 text-xs text-slate-300">
          <p className="font-semibold text-cyan-300">Mission</p>
          <p className="mt-1">
            Simulation-first. Safety-first. Non-addictive by design.
          </p>
        </div>

        <div className="space-y-1">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.to === "/"}
              className={({ isActive }) =>
                `block rounded-xl px-3 py-2 text-sm transition ${
                  isActive
                    ? "bg-cyan-500/15 text-cyan-300"
                    : "text-slate-300 hover:bg-slate-800 hover:text-white"
                }`
              }
            >
              {link.label}
            </NavLink>
          ))}
        </div>
      </nav>
    </aside>
  );
}
