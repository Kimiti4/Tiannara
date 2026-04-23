import { useState } from "react";
import DiscoveryLab from "./DiscoveryLab";
import AutonomousLab from "./AutonomousLab";

export default function ControlCenter() {
  const [tab, setTab] = useState("discovery");

  return (
    <div style={{ padding: 20, color: "white" }}>
      <h1>Tiannara Control Center</h1>

      {/* NAV */}
      <div style={{ marginBottom: 20 }}>
        <button onClick={() => setTab("discovery")}>Discovery</button>
        <button onClick={() => setTab("autonomous")}>Autonomous</button>
      </div>

      {/* CONTENT */}
      {tab === "discovery" && <DiscoveryLab />}
      {tab === "autonomous" && <AutonomousLab />}
    </div>
  );
}