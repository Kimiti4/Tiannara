export default function StatusCard({ title, value, subtitle, tone = "default" }) {
  const toneClasses = {
    default: "border-slate-800 bg-slate-900",
    success: "border-emerald-800/60 bg-emerald-950/20",
    warning: "border-amber-800/60 bg-amber-950/20",
    info: "border-cyan-800/60 bg-cyan-950/20",
  };

  return (
    <div className={`rounded-2xl border p-4 shadow-sm ${toneClasses[tone] || toneClasses.default}`}>
      <p className="text-sm text-slate-400">{title}</p>
      <p className="mt-2 text-2xl font-semibold text-white">{value}</p>
      {subtitle ? <p className="mt-1 text-sm text-slate-400">{subtitle}</p> : null}
    </div>
  );
}
