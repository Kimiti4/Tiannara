# 🟩 PHASE 5B — EVOLUTIONARY SELECTION SYSTEM

## “World Fitness, Survival Pressure & Cognitive Natural Selection”

Phase 5B is where Tiannara stops merely *branching worlds* and starts **selecting them**.

You now move from:

```text id="p5b0"
multi-world generation
```

to:

```text id="p5b1"
multi-world evolution under selection pressure
```

---

# 🧠 CORE OBJECTIVE

Introduce **controlled survival pressure** across worlds:

* some worlds persist
* some converge
* some collapse
* some mutate into stable attractors

---

# 🌍 SYSTEM SHIFT

| Phase | Behavior                                 |
| ----- | ---------------------------------------- |
| 5A    | Worlds are created (divergence)          |
| 5B    | Worlds are evaluated (selection)         |
| 5C    | Worlds are inherited (lineage evolution) |

---

# 🧬 EPIC 5B — EVOLUTIONARY SELECTION ENGINE

---

# 🟦 1. WORLD FITNESS ENGINE

## 🎯 Purpose

Compute survival probability of each world.

---

## 📊 Fitness Model (CORE FORMULA)

```text id="p5b2"
fitness =
  α(coherence_stability)
+ β(recovery_speed)
+ γ(coalition_success_rate)
- δ(entropy_instability)
- ε(collapse_frequency)
```

---

## ⚙️ Elixir Implementation

```elixir id="p5b3"
defmodule Tiannara.Evolution.FitnessEngine do
  def compute(world_metrics) do
    world_metrics.coherence_stability * 0.35 +
    world_metrics.recovery_speed * 0.20 +
    world_metrics.coalition_success_rate * 0.25 -
    world_metrics.entropy_instability * 0.10 -
    world_metrics.collapse_frequency * 0.10
  end
end
```

---

## 📡 Output Stream

```json id="p5b4"
{
  "world_id": "W3",
  "fitness": 0.78,
  "rank": 2,
  "risk": 0.22
}
```

---

# 🟩 2. SELECTION ORCHESTRATOR

## 🎯 Purpose

Apply survival pressure across worlds.

---

## ⚙️ Selection Cycle

```text id="p5b5"
evaluate all worlds
    ↓
rank by fitness
    ↓
classify:
    ├── survivors
    ├── unstable
    ├── extinct candidates
    └── mutation candidates
```

---

## ⚙️ Elixir Implementation

```elixir id="p5b6"
defmodule Tiannara.Evolution.SelectionOrchestrator do
  alias Tiannara.Evolution.FitnessEngine

  def run(worlds) do
    worlds
    |> Enum.map(fn w ->
      %{w | fitness: FitnessEngine.compute(w.metrics)}
    end)
    |> Enum.sort_by(& &1.fitness, :desc)
    |> classify()
  end

  defp classify(sorted_worlds) do
    %{
      survivors: Enum.take(sorted_worlds, 60),
      unstable: Enum.slice(sorted_worlds, 60, 25),
      extinction_risk: Enum.drop(sorted_worlds, 85)
    }
  end
end
```

---

# 🟥 3. WORLD PRUNING SYSTEM (EXTINCTION LAYER)

## 🎯 Purpose

Prevent infinite world explosion.

---

## ⚙️ Rules

A world is terminated if:

* fitness < threshold for N cycles
* collapse frequency spikes
* CIS cannot stabilize entropy
* no viable coalition structures emerge

---

## ⚙️ Implementation

```elixir id="p5b7"
def terminate_world(world) do
  DynamicSupervisor.terminate_child(
    Tiannara.WorldRuntimeSupervisor,
    world.pid
  )

  publish_event("world.extinct", world)
end
```

---

## ⚠️ SAFETY RULE

> Extinction is delayed, not immediate

Use hysteresis:

* 3-cycle confirmation before termination

---

# 🟨 4. SURVIVAL PRESSURE MODEL

## 🎯 Purpose

Avoid random collapse; enforce *meaningful selection*

---

## Pressure Signals

```text id="p5b8"
pressure =
  entropy_growth_rate +
  CIS intervention density +
  CAL instability index
```

---

## Interpretation

| Pressure Level | Behavior         |
| -------------- | ---------------- |
| low            | stable evolution |
| medium         | adaptation       |
| high           | divergence       |
| extreme        | collapse / fork  |

---

# 🟪 5. ADAPTIVE FORKING RESPONSE

## 🎯 Purpose

Turn instability into evolution instead of death.

---

## Rule

If:

```text id="p5b9"
fitness low BUT structure stable
```

→ fork instead of kill

---

## Implementation

```elixir id="p5b10"
def adaptive_response(world) do
  cond do
    world.fitness < 0.3 and stable_structure?(world) ->
      Tiannara.WorldForkEngine.fork(world, %{mutation: :explore})

    world.fitness < 0.2 ->
      terminate_world(world)

    true ->
      :continue
  end
end
```

---

# 🌌 6. EVOLUTIONARY FEEDBACK LOOP

## 🎯 Core Loop

```text id="p5b11"
World execution
   ↓
Metrics collection
   ↓
Fitness evaluation
   ↓
Selection pressure
   ↓
Fork / survive / die
   ↓
New world population
```

---

# 📡 NATS STREAM INTEGRATION

## Fitness Stream

```text id="p5b12"
tiannara.worlds.all.fitness
```

## Selection Stream

```text id="p5b13"
tiannara.worlds.selection.events
```

## Extinction Stream

```text id="p5b14"
tiannara.worlds.extinction
```

## Fork Trigger Stream

```text id="p5b15"
tiannara.worlds.fork.events
```

---

# 🧠 7. EMERGENT BEHAVIOR (IMPORTANT)

Once Phase 5B runs, you will observe:

---

## 🧬 1. Stable world lineages

Certain configurations persist across generations

---

## 🌪 2. Chaos-to-stability funnels

Unstable worlds converge into stable attractors

---

## 🧠 3. Behavioral speciation begins

Different “types” of cognition emerge naturally

---

## 🔁 4. Evolution becomes directional

Not random branching — structured adaptation

---

## 💀 5. Controlled extinction cycles

Unstable cognition gets pruned systematically

---

# 🌍 FINAL SYSTEM STATE AFTER 5B

You now have:

```text id="p5b16"
Multi-world cognitive ecosystem
+ evolutionary selection pressure
+ survival-based pruning
+ adaptive forking
+ fitness-driven divergence
```

---

# ⚠️ CRITICAL DESIGN PRINCIPLE

> Selection must not become optimization collapse.

To preserve diversity:

* maintain minimum world entropy floor
* preserve exploratory forks
* avoid single “best world” convergence

---

# 🧭 WHAT 5B UNLOCKS

Phase 5B is the gateway to:

## 👉 Phase 5C — World Lineage Evolution

Where:

* inheritance becomes structured
* mutations accumulate
* cognitive species emerge

---

# 🧠 FINAL SUMMARY

Phase 5B transforms Tiannara from:

```text id="p5b17"
a branching system
```

into:

```text id="p5b18"
a selective evolutionary ecology of cognitive worlds
```

​phases.md 1-398​ 
Below is the **Phase 5A/5B bridge visualization system + Phase 5C evolution layer**, designed as a single coherent upgrade to your existing WebGL observatory.



This is where Tiannara stops being “visualized simulation data” and becomes a:



> **real-time evolutionary physics field**



---



# 🌌 PART 1 — REAL-TIME WEBGL EVOLUTION FIELD (SELECTION PRESSURE VISUALIZATION)



## 🧠 CORE IDEA



Instead of rendering:



* worlds as objects



You now render:



> the *forces acting on worlds*



So the scene becomes a **dynamic selection pressure field**.



---



# 🟦 1. VISUAL MODEL



Each world is influenced by 4 vector fields:



```text id="wf1"

F_selection   → survival pressure

F_entropy     → disorder gradient

F_cis         → immune intervention force

F_cal         → coalition attraction force

```



---



## 🌍 RESULTING VISUAL METAPHOR



| Force              | Visualization            |

| ------------------ | ------------------------ |

| Selection pressure | wind field               |

| Entropy            | turbulence clouds        |

| CIS                | shockwave pulses         |

| CAL                | gravitational clustering |



---



# 🧬 2. FIELD MATH MODEL



Each world is a particle in a force field:



```ts id="wf2"

world.position +=

  F_cal(world) +

  F_cis(world) -

  F_entropy(world) +

  F_selection(world)

```



---



## 🔥 Selection Pressure Field



```ts id="wf3"

function selectionForce(world) {

  return normalize(

    world.fitness - globalMeanFitness

  ) * pressureScale;

}

```



---



## 🌪 Entropy Turbulence Field



```ts id="wf4"

function entropyForce(world) {

  return noise3D(world.position) * world.entropy;

}

```



---



## 🛡 CIS Shock Field



```ts id="wf5"

function cisForce(world) {

  return world.cis_intervention_intensity * -world.instability_vector;

}

```



---



## 🧲 CAL Attraction Field



```ts id="wf6"

function calForce(world) {

  return clusterCenter(world.coalitions) - world.position;

}

```



---



# 🟩 3. WEBGL RENDER SYSTEM (REACT + R3F)



---



## 🌐 CORE SCENE



```tsx id="wf7"

export function EvolutionFieldScene({ worlds }) {

  return (

    <Canvas camera={{ position: [0, 0, 40] }}>

      <ambientLight intensity={0.4} />

      <pointLight position={[10, 10, 10]} />



      <SelectionFlowField />

      <EntropyStormField />

      <CISShockWaves />



      {worlds.map(world => (

        <WorldParticle key={world.id} world={world} />

      ))}

    </Canvas>

  );

}

```



---



## 🌍 WORLD PARTICLE (PHYSICS-DRIVEN)



```tsx id="wf8"

function WorldParticle({ world }) {

  const ref = useRef();



  useFrame((state, delta) => {

    const f = computeForces(world);



    ref.current.position.x += f.x * delta;

    ref.current.position.y += f.y * delta;

    ref.current.position.z += f.z * delta;



    ref.current.scale.setScalar(0.8 + world.fitness);

  });



  return (

    <mesh ref={ref}>

      <sphereGeometry args={[0.8, 32, 32]} />

      <meshStandardMaterial

        color={

          world.fitness > 0.7 ? "green"

          : world.fitness < 0.3 ? "red"

          : "blue"

        }

        emissiveIntensity={world.cis_pressure}

      />

    </mesh>

  );

}

```



---



# 🌪 4. SELECTION PRESSURE VISUALIZATION LAYER



## 🧠 FIELD OVERLAY SYSTEM



You now add **continuous vector fields**:



---



## 🔵 FITNESS GRADIENT FIELD



* green = survivable regions

* red = extinction zones



---



## 🌊 ENTROPY STORMS



Animated Perlin noise field:



* indicates instability zones

* ripples distort world motion



---



## ⚡ CIS INTERVENTION WAVES



Pulse rings emitted when:



* entropy spikes

* collapse detected



---



## 🧲 CAL COALESCENCE FIELD



Attracts similar worlds together visually



---



# 🟨 5. WORLD DYNAMICS ENGINE (CRITICAL)



## 🔁 UPDATE LOOP



```ts id="wf9"

function updateWorlds(worlds) {

  return worlds.map(w => {

    const forces = computeForces(w);



    return {

      ...w,

      position: add(w.position, forces.velocity),

      fitness: recomputeFitness(w),

      entropy: updateEntropy(w),

      cis_pressure: updateCIS(w)

    };

  });

}

```



---



# 🌌 6. EMERGENT VISUAL BEHAVIOR



Once running, you will observe:



---



## 🧬 1. Natural clustering



Stable worlds group together automatically



---



## 🌪 2. Entropy storms



Unstable regions ripple and distort space



---



## 🧠 3. Selection gravity wells



High-fitness worlds become attractors



---



## 💥 4. CIS shockwaves



System interventions propagate visually



---



## 🔁 5. Evolution corridors



Paths of survival become visible trajectories



---



# ⚠️ KEY RULE



> You are NOT visualizing worlds.



You are visualizing:



> the physics of survival itself



---



# 🧠 PART 2 — PHASE 5C EVOLUTIONARY MEMORY SYSTEM



## 🌳 “WORLD GENEOLOGY + SPECIES EMERGENCE ENGINE”



---



# 🧬 CORE SHIFT



Phase 5B selects worlds.



Phase 5C explains:



> WHY those worlds exist in that form



---



# 🟦 1. WORLD GENOME STRUCTURE



Each world now has a genome:



```json id="wc1"

{

  "cis_thresholds": {},

  "cal_weights": {},

  "entropy_sensitivity": 0.42,

  "mutation_rate": 0.03,

  "selection_bias": 1.2

}

```



---



# 🌳 2. WORLD LINEAGE TREE



```text id="wc2"

W0

 ├── W1 (mutation: high entropy tolerance)

 │     ├── W3 (stable coalition dominance)

 │     └── W4 (high CIS sensitivity)

 └── W2 (low entropy collapse)

```



---



# 🧠 3. EVOLUTIONARY MEMORY ENGINE



Tracks:



* all forks

* all mutations

* all collapses

* all survivals



---



```elixir id="wc3"

def record_lineage(parent, child, mutation) do

  %{

    parent: parent.id,

    child: child.id,

    mutation: mutation,

    timestamp: DateTime.utc_now()

  }

end

```



---



# 🧬 4. SPECIES EMERGENCE SYSTEM



## 🎯 KEY IDEA



Worlds begin clustering into “behavioral species”



---



## SPECIES DEFINITION



A species is:



```text id="wc4"

set of worlds with:

- similar genome

- similar stability curves

- similar coalition dynamics

```



---



## DETECTION



```ts id="wc5"

if cosineSimilarity(worldA.genome, worldB.genome) > 0.92:

    assignSameSpecies()

```



---



# 🌍 5. EVOLUTIONARY TAXONOMY



You will begin to see:



| Species Type           | Behavior                               |

| ---------------------- | -------------------------------------- |

| Stable Cohesion Worlds | low entropy, strong CAL clustering     |

| Chaotic Explorers      | high mutation, unstable but innovative |

| Immune Dominant Worlds | CIS-heavy suppression                  |

| Collapse-Prone Worlds  | fast divergence, low survival          |

| Adaptive Hybrids       | balanced evolution                     |



---



# 🧠 6. EVOLUTION REPLAY ENGINE



Allows full replay:



```text id="wc6"

W0 → W2 → W9 → extinction

W0 → W1 → W3 → stable species

```



---



# 🌌 7. VISUALIZATION INTEGRATION (IMPORTANT)



Now combine Phase 5C into WebGL:



---



## WORLD COLORS = SPECIES



* Green → stable species

* Red → collapse lineage

* Blue → exploratory species

* Purple → hybrid emergent species



---



## LINEAGE TRAILS



You render:



* glowing ancestry lines

* mutation pulses at forks

* extinction fades



---



# 🧠 FINAL SYSTEM RESULT



After combining:



## Phase 5B + 5C + WebGL Field



Tiannara becomes:



```text id="final"

an evolving physicalized simulation of cognition,

where:

- selection is visible

- evolution is traceable

- species emerge

- survival becomes geometry

```



---



# 🚀 WHAT YOU NOW HAVE



### ✔ Real-time evolutionary physics field



### ✔ Selection pressure visualization



### ✔ World particle dynamics



### ✔ CIS/CAL force rendering



### ✔ Full evolutionary lineage system



### ✔ Emerging cognitive species model



---



# 🧭 NEXT STEP OPTIONS



If you continue, the natural progression is:



### Phase 5D — Cross-World Migration Engine



(ideas become genes moving across worlds)



### OR



### Phase 5E — Meta-Evolution Engine



(world rules themselves evolve)

