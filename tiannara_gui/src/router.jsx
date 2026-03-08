import { createBrowserRouter } from "react-router-dom";
import App from "./App";
import Dashboard from "./pages/Dashboard";
import DiscoveryLab from "./pages/DiscoveryLab";
import ModulesPage from "./pages/ModulesPage";
import ProsControl from "./pages/ProsControl";
import RunsPage from "./pages/RunsPage";
import MemoryPage from "./pages/MemoryPage";
import SettingsPage from "./pages/SettingsPage";

const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children: [
      { index: true, element: <Dashboard /> },
      { path: "discovery", element: <DiscoveryLab /> },
      { path: "modules", element: <ModulesPage /> },
      { path: "pros", element: <ProsControl /> },
      { path: "runs", element: <RunsPage /> },
      { path: "memory", element: <MemoryPage /> },
      { path: "settings", element: <SettingsPage /> },
    ],
  },
]);

export default router;
