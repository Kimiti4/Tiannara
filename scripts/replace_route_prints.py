"""One-off: replace print() with logging in tiannara_api/routes/*.py"""
import re
from pathlib import Path

ROUTES = Path(__file__).resolve().parents[1] / "tiannara_api" / "routes"

for path in sorted(ROUTES.glob("*.py")):
    text = path.read_text(encoding="utf-8")
    if "print(" not in text:
        continue
    if "logger = logging.getLogger" not in text:
        lines = text.splitlines(keepends=True)
        last_import = 0
        for i, line in enumerate(lines):
            if line.startswith(("import ", "from ")):
                last_import = i
        lines.insert(last_import + 1, "\nimport logging\n\nlogger = logging.getLogger(__name__)\n")
        text = "".join(lines)

    def level_for(inner: str) -> str:
        low = inner.lower()
        if any(x in low for x in ("error", "failed", "traceback", "❌")):
            return "error"
        if any(x in low for x in ("warning", "warn", "⚠", "not available")):
            return "warning"
        if "disconnect" in low:
            return "info"
        return "info"

    def repl(m: re.Match) -> str:
        inner = m.group(1)
        return f"logger.{level_for(inner)}({inner})"

    while "print(" in text:
        text = re.sub(r"print\(([^)]+)\)", repl, text, count=1)
    path.write_text(text, encoding="utf-8")
    print("updated", path.name)
