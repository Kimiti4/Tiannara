import { createBrowserRouter } from "react-router-dom";
import App from "./App";
import AutonomousLab from "./pages/AutonomousLab";
import Dashboard from "./pages/Dashboard";
import DiscoveryLab from "./pages/DiscoveryLab";
import EvolutionLab from "./pages/EvolutionLab";
import MemoryLab from "./pages/MemoryLab";
import ModulesPage from "./pages/ModulesPage";
import ProsControl from "./pages/ProsControl";
import RunsPage from "./pages/RunsPage";
import SettingsPage from "./pages/SettingsPage";

const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children: [
      { index: true, element: <Dashboard /> },
      { path: "discovery", element: <DiscoveryLab /> },
      { path: "evolution", element: <EvolutionLab /> },
      { path: "autonomous", element: <AutonomousLab /> },
      { path: "modules", element: <ModulesPage /> },
      { path: "pros", element: <ProsControl /> },
      { path: "runs", element: <RunsPage /> },
      { path: "memory", element: <MemoryLab /> },
      { path: "settings", element: <SettingsPage /> },
    ],
  },
]);

export default router;
