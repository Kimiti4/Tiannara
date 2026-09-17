alias Tiannara.MCALv2.{Supervisor, RecursiveFeedbackLoop, IdentityTree}
require Logger

# Boot the Supervisor
Supervisor.start_link()

# Allow GenServer to initialize
Process.sleep(100)

Logger.info("\n=== STARTING MCAL v2 RIFE DEMONSTRATION ===")

# Execute the recursive feedback loop
fittest_identity = RecursiveFeedbackLoop.cycle()

Logger.info("\n=== POST-CYCLE IDENTITY TREE STATE ===")
all_identities = IdentityTree.get_all_identities()
Logger.info("Total identities in memory: #{length(all_identities)}")

Logger.info("\n=== FITTEST IDENTITY SUMMARY ===")
Logger.info("ID: #{fittest_identity.id}")
Logger.info("Cognitive Policy: #{fittest_identity.cognitive_policy}")
Logger.info("Causal Bias: #{Float.round(fittest_identity.causal_bias, 2)}")
Logger.info("Fitness Score: #{fittest_identity.fitness_score}")
