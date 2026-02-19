from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator
from tiannara_core.cognition.decision_engine import DecisionEngine
from tiannara_core.action.action_layer import ActionLayer
from tiannara_core.cognition.skill_memory import SkillMemory


def simulate_outcome(intent, targets, ctx):
    """
    Simple scoring rule:
    - precision wants grip with moderate damping and lower force
    - balance wants stabilize with higher damping
    """
    if intent == "grip":
        gf = targets.get("grip_force", 0.0)
        d = targets.get("damping", 0.0)
        if "precision" in ctx:
            return "good" if (gf <= 0.55 and 0.15 <= d <= 0.50) else "bad"
        return "good" if (gf <= 0.75 and 0.10 <= d <= 0.60) else "bad"

    if intent == "stabilize":
        d = targets.get("damping", 0.0)
        return "good" if d >= 0.35 else "bad"

    if intent == "release":
        return "good"

    return "bad"


def main():
    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()
    action_layer = ActionLayer()

    skill = SkillMemory()
    decider = DecisionEngine(min_confidence=0.30, safety_fallback_intent="stabilize", skill_memory=skill)

    # Build a small base of episodic memories
    base_input = [
        {"joint_angles": [10, 20, 30], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [15, 22, 35], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [12, 18, 33], "intent": "release", "tags": ["hand"]},
    ]

    for d in base_input:
        context = processor.process(d)
        memory.store(context, tags=d["tags"])

    # Consolidate -> patterns
    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    # Online training loop
    contexts = [["precision"], ["precision"], ["hand"], ["balance"], ["unknown"], ["hand"], ["balance"], ["precision"]]

    print("\n=== Day 10B Skill Learning ===\n")

    for epoch in range(1, 11):
        good_count = 0
        print(f"\n--- Epoch {epoch} ---")

        for ctx in contexts:
            decision = decider.decide(memory.memory_store, ctx)
            action = action_layer.intent_to_action(decision["intent"], decision["confidence"], ctx)

            outcome = simulate_outcome(decision["intent"], action["targets"], ctx)
            skill.update(ctx, decision["intent"], outcome)

            if outcome == "good":
                good_count += 1

            print(f"ctx={ctx} intent={decision['intent']} conf={decision['confidence']:.2f} "
                  f"outcome={outcome} skill_bias={decision.get('chosen_breakdown', {}).get('skill_bias', 0.0):.2f}")

        print(f"Epoch score: {good_count}/{len(contexts)} good")

    # Show learned preference summary
    print("\n--- Learned Skill Stats (summary) ---")
    for tag, intents in skill.stats.items():
        for intent, s in intents.items():
            print(f"tag={tag:10s} intent={intent:10s} good={s['good']} bad={s['bad']}")


if __name__ == "__main__":
    main()
