defmodule TiannaraWeb.Layouts do
  @moduledoc """
  Defines direct function layouts for the Tiannara Web interface.
  Avoids dynamic loading issues by housing root/1 and app/1 in Elixir code.
  """
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="h-full bg-slate-950 text-slate-100">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={assigns[:csrf_token]} />
        <title>Tiannara Research OS</title>
        
        <!-- Google Fonts: Outfit & Inter -->
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
        
        <!-- Premium Custom Dark CSS styling -->
        <style>
          :root {
            --font-outfit: 'Outfit', sans-serif;
            --font-inter: 'Inter', sans-serif;
            
            /* HSL Tailored Colors */
            --bg-base: 224 71% 4%;
            --bg-surface: 224 71% 8%;
            --bg-card: 224 71% 12%;
            --border-glow: 217 91% 60%;
            --primary: 217 91% 60%;
            --primary-glow: 217 91% 60% / 0.15;
            --accent: 270 91% 65%;
            --accent-glow: 270 91% 65% / 0.15;
            
            --success: 142 76% 45%;
            --warning: 38 92% 50%;
            --danger: 350 89% 60%;
          }

          body {
            font-family: var(--font-inter);
            background: radial-gradient(circle at 50% 0%, hsl(224 71% 10%) 0%, hsl(var(--bg-base)) 100%) no-repeat;
            background-attachment: fixed;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            color: hsl(210 40% 98%);
          }

          h1, h2, h3, h4, .font-heading {
            font-family: var(--font-outfit);
            font-weight: 600;
          }

          /* Scrollbar */
          ::-webkit-scrollbar {
            width: 8px;
            height: 8px;
          }
          ::-webkit-scrollbar-track {
            background: hsl(var(--bg-base));
          }
          ::-webkit-scrollbar-thumb {
            background: hsl(var(--bg-card));
            border-radius: 4px;
          }
          ::-webkit-scrollbar-thumb:hover {
            background: hsl(var(--primary));
          }

          /* Glassmorphic Navbar */
          .navbar {
            backdrop-filter: blur(16px);
            background: hsla(224, 71%, 8%, 0.7);
            border-bottom: 1px solid hsla(217, 91%, 60%, 0.15);
            position: sticky;
            top: 0;
            z-index: 100;
          }

          /* Glass Cards */
          .glass-card {
            background: hsla(224, 71%, 12%, 0.6);
            backdrop-filter: blur(12px);
            border: 1px solid hsla(217, 91%, 60%, 0.1);
            border-radius: 12px;
            box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          }
          .glass-card:hover {
            border-color: hsla(217, 91%, 60%, 0.25);
            box-shadow: 0 8px 32px 0 hsla(217, 91%, 60%, 0.1);
            transform: translateY(-2px);
          }

          /* Micro-animations */
          @keyframes pulse-glow {
            0%, 100% { opacity: 0.6; }
            50% { opacity: 1; }
          }
          .pulse-glow {
            animation: pulse-glow 2s infinite ease-in-out;
          }

          /* Custom styling helper classes */
          .nav-link {
            color: hsl(215 20% 65%);
            text-decoration: none;
            font-family: var(--font-outfit);
            font-weight: 500;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            transition: all 0.2s;
          }
          .nav-link:hover, .nav-link.active {
            color: hsl(210 40% 98%);
            background: hsla(217, 91%, 60%, 0.1);
          }

          .flex { display: flex; }
          .flex-col { flex-direction: column; }
          .flex-row { flex-direction: row; }
          .flex-grow { flex-grow: 1; }
          .items-center { align-items: center; }
          .justify-between { justify-content: space-between; }
          .justify-center { justify-content: center; }
          .gap-2 { gap: 0.5rem; }
          .gap-3 { gap: 0.75rem; }
          .gap-4 { gap: 1rem; }
          .gap-6 { gap: 1.5rem; }
          .p-8 { padding: 2rem; }
          .py-4 { padding-top: 1rem; padding-bottom: 1rem; }
          .px-6 { padding-left: 1.5rem; padding-right: 1.5rem; }
          .py-6 { padding-top: 1.5rem; padding-bottom: 1.5rem; }
          .px-8 { padding-left: 2rem; padding-right: 2rem; }
          .max-w-7xl { max-w: 80rem; }
          .mx-auto { margin-left: auto; margin-right: auto; }
          .w-full { width: 100%; }
          .h-full { height: 100%; }
          .min-h-screen { min-height: 100vh; }
          .text-slate-500 { color: hsl(215 15% 50%); }
          .text-xs { font-size: 0.75rem; }
          .text-sm { font-size: 0.875rem; }
          .text-lg { font-size: 1.125rem; }
          .text-xl { font-size: 1.25rem; }
          .text-2xl { font-size: 1.5rem; }
          .text-3xl { font-size: 1.875rem; }
          .font-extrabold { font-weight: 800; }
          .font-bold { font-weight: 700; }
          .tracking-wider { tracking-wider: 0.05em; }
          .text-transparent { color: transparent; }
          .bg-clip-text { -webkit-background-clip: text; background-clip: text; }
          .bg-gradient-to-r { background-image: linear-gradient(to right, var(--tw-gradient-stops)); }
          .from-blue-400 { --tw-gradient-from: #60a5fa; --tw-gradient-to: rgb(96 165 250 / 0); --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to); }
          .to-indigo-400 { --tw-gradient-to: #818cf8; }
          .rounded { border-radius: 0.25rem; }
          .bg-blue-500\/20 { background-color: rgb(59 130 246 / 0.2); }
          .text-blue-400 { color: #60a5fa; }
          .border { border-width: 1px; }
          .border-t { border-top-width: 1px; }
          .border-slate-800 { border-color: hsl(215 25% 18%); }
          .grid { display: grid; }
          .grid-cols-1 { grid-template-columns: repeat(1, minmax(0, 1fr)); }
          .grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
          .grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
          .col-span-2 { grid-column: span 2 / span 2; }
          .mt-4 { margin-top: 1rem; }
          .mt-6 { margin-top: 1.5rem; }
          .mb-4 { margin-bottom: 1rem; }
          .font-semibold { font-weight: 600; }
          .rounded-lg { border-radius: 0.5rem; }
          .p-6 { padding: 1.5rem; }
          .p-4 { padding: 1rem; }
          .text-slate-400 { color: hsl(215 15% 65%); }
          .text-slate-300 { color: hsl(215 15% 75%); }
          .text-slate-100 { color: hsl(210 40% 98%); }
          .border-slate-700 { border-color: hsl(215 25% 25%); }
          .bg-slate-900 { background-color: hsl(224 71% 6%); }
          .cursor-pointer { cursor: pointer; }
          .hover\:text-white:hover { color: #fff; }
          .hover\:bg-blue-600:hover { background-color: #2563eb; }
          .text-indigo-400 { color: #818cf8; }
          .text-emerald-400 { color: #34d399; }
          .text-amber-400 { color: #fbbf24; }
          .text-rose-400 { color: #f87171; }
          .bg-emerald-500\/10 { background-color: rgb(16 185 129 / 0.1); }
          .border-emerald-500\/20 { border-color: rgb(16 185 129 / 0.2); }
          .bg-amber-500\/10 { background-color: rgb(245 158 11 / 0.1); }
          .border-amber-500\/20 { border-color: rgb(245 158 11 / 0.2); }
          .bg-indigo-500\/10 { background-color: rgb(99 102 241 / 0.1); }
          .border-indigo-500\/20 { border-color: rgb(99 102 241 / 0.2); }
          .bg-rose-500\/10 { background-color: rgb(244 63 94 / 0.1); }
          .border-rose-500\/20 { border-color: rgb(244 63 94 / 0.2); }
          .bg-blue-500\/10 { background-color: rgb(59 130 246 / 0.1); }
          .border-blue-500\/20 { border-color: rgb(59 130 246 / 0.2); }
          select option {
            background-color: hsl(224 71% 8%) !important;
            color: hsl(210 40% 98%) !important;
          }
        </style>
      </head>
      <body class="h-full">
        {@inner_content}
        <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.10/priv/static/phoenix.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@0.20.2/priv/static/phoenix_live_view.min.js"></script>
        <script>
          let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
          let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {params: {_csrf_token: csrfToken}})
          liveSocket.connect()
        </script>
      </body>
    </html>
    """
  end

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <header class="navbar py-4 px-6 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <span class="text-xl font-extrabold tracking-wider text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400 font-heading">
            TIANNARA // RESEARCH OS
          </span>
          <span class="text-xs px-2 py-0.5 rounded bg-blue-500/20 text-blue-400 border border-blue-500/30 pulse-glow font-semibold">
            ACTIVE COGNITION
          </span>
        </div>
        
        <nav class="flex items-center gap-2">
          <a href="/mission-control" class="nav-link">Mission Control</a>
          <a href="/discoveries" class="nav-link">Discoveries</a>
          <a href="/laws" class="nav-link">Laws</a>
          <a href="/theories" class="nav-link">Theories</a>
          <a href="/unknowns" class="nav-link">Unknowns</a>
          <a href="/interventions" class="nav-link">Interventions</a>
          <a href="/portfolio" class="nav-link">Portfolio</a>
          <a href="/worlds" class="nav-link">Worlds</a>
          <a href="/constitutions" class="nav-link">Constitutions</a>
          <a href="/programs" class="nav-link">Programs</a>
          <a href="/research-map" class="nav-link">Research Map</a>
          <a href="/domains" class="nav-link">Domains</a>
          <a href="/civilization-atlas" class="nav-link">Civilization Atlas</a>
          <a href="/orbit-atlas" class="nav-link">Orbit Atlas</a>
          <a href="/orbit-navigation" class="nav-link">Orbit Navigation</a>
          <a href="/orbit-genesis" class="nav-link">Orbit Genesis</a>
          <a href="/orbit-memory" class="nav-link">Orbit Memory</a>
          <a href="/orbit-ecology" class="nav-link">Orbit Ecology</a>
        </nav>
      </header>

      <main class="flex-grow p-8 max-w-7xl mx-auto w-full">
        <%= @inner_content %>
      </main>

      <footer class="py-6 px-8 border-t border-slate-800 text-center text-xs text-slate-500 flex justify-between items-center max-w-7xl mx-auto w-full">
        <div>Tiannara Self-Modeling Research Organism &copy; 2026</div>
        <div class="flex gap-4">
          <span>DVR: 1.0</span>
          <span>Surprise Index: 0.0496</span>
          <span>Status: Verified</span>
        </div>
      </footer>
    </div>
    """
  end
end
