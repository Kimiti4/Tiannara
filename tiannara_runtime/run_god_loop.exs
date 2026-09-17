alias Tiannara.GodLoop.Supervisor
require Logger

# Boot the God-Loop Supervisor
Supervisor.start_link()

# Allow GenServer to initialize
Process.sleep(100)

Logger.info("\n🌌 === STARTING GOD-LOOP DEMONSTRATION === 🌌")

# Initial State
state_0 = Supervisor.get_state()
Logger.info("Initial State: MC(Diversity: #{state_0.mc_state.identity_diversity}), OPC(Vol: #{state_0.opc_state.rule_volatility}), CIS(Rigidity: #{state_0.cis_state.rigidity})")

# Tick 1: Expecting MCAL to detect high mutation pressure (due to static_epochs) 
# and CIS to detect immune tyranny.
Supervisor.tick()
Process.sleep(100)

# Tick 2: Expecting OPC to detect diversification pressure and force causal volatility.
Supervisor.tick()
Process.sleep(100)

# Tick 3: System stabilizes around new rules.
Supervisor.tick()
Process.sleep(100)

Logger.info("\n🌌 === FINAL GOD-LOOP STATE === 🌌")
state_f = Supervisor.get_state()
Logger.info("Final State: MC(Diversity: #{state_f.mc_state.identity_diversity}), OPC(Vol: #{state_f.opc_state.rule_volatility}), CIS(Rigidity: #{state_f.cis_state.rigidity})")
