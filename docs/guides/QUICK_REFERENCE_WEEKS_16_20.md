# Quick Reference Guide - Weeks 16-20 Implementation

**Quick access to all usability and coordination features**

---

## 📚 Module Imports

```python
# Week 16: Agent Coordination
from tiannara_core.agents.coordination_framework import (
    AgentCoordinationFramework,
    AgentProfile,
    AgentRole,
    TaskComplexity
)

# Weeks 17-20: Usability Components
from tiannara_core.usability.temporal_parser import TemporalExpressionParser
from tiannara_core.usability.context_preservation import ContextPreservationSystem
from tiannara_core.usability.intent_recognition import IntentRecognizer
from tiannara_core.usability.ux_enhancements import UXEnhancementEngine
```

---

## 🚀 Quick Start Examples

### 1. Agent Coordination Framework

```python
# Initialize
framework = AgentCoordinationFramework()

# Register agents
agent = AgentProfile(
    agent_id="analyzer_01",
    role=AgentRole.ANALYZER,
    capabilities=["data_analysis", "statistics"],
    expertise_areas=["prediction", "analysis"]
)
framework.register_agent(agent)

# Analyze task
task = framework.analyze_task_requirements(
    task_id="task_001",
    description="Predict football match outcome",
    domain="sports_prediction",
    required_skills=["data_analysis", "probability"],
    complexity=TaskComplexity.MODERATE,
    priority=7
)

# Select agents
selected = framework.select_agents_for_task("task_001")

# Build consensus
consensus = framework.build_consensus(
    task_id="task_001",
    agent_votes={"agent1": "home_win", "agent2": "home_win"},
    agent_weights={"agent1": 0.9, "agent2": 0.8}
)
```

### 2. Temporal Expression Parser

```python
parser = TemporalExpressionParser()

# Parse single expression
result = parser.parse("tomorrow")
print(result.start_time)  # 2026-05-08 00:00:00
print(result.confidence)  # 0.95

# Extract multiple expressions
results = parser.extract_all_temporal("Schedule meeting tomorrow and review data from 3 days ago")
for r in results:
    print(f"{r.original_text}: {r.time_type.value}")
```

### 3. Context Preservation System

```python
cps = ContextPreservationSystem()

# Add context
cps.add_context(
    content="User prefers football predictions",
    context_type="preference",
    importance=0.9
)

# Add conversation turn
cps.add_conversation_turn(
    user_message="What are tomorrow's predictions?",
    agent_response="Team A has 65% win probability",
    intent="prediction_request"
)

# Retrieve relevant context
relevant = cps.get_relevant_context("football predictions", max_items=5)

# Get summary
summary = cps.summarize_context()

# Export/Import
exported = cps.export_context()
cps2 = ContextPreservationSystem()
cps2.import_context(exported)
```

### 4. Intent Recognition System

```python
recognizer = IntentRecognizer()

# Recognize intent
result = recognizer.recognize_intent("Predict tomorrow's football match")

print(result.primary_intent)     # "get_sports_prediction"
print(result.category.value)     # "prediction"
print(result.confidence)         # 0.95

# Access entities
for entity in result.entities:
    print(f"{entity.entity_type}: {entity.value}")
    # date: tomorrow
    # sport: football

# Check if clarification needed
if result.requires_clarification:
    print(result.clarification_question)
```

### 5. UI/UX Enhancement Engine

```python
engine = UXEnhancementEngine()

# Format response
prediction_data = {
    "sport": "Football",
    "outcome": "Home Win",
    "confidence": 0.72,
    "reasoning": "Strong home form",
    "factors": ["Home advantage", "Away injuries"],
    "recommendation": "Moderate confidence"
}

formatted = engine.format_response(
    prediction_data,
    response_type="prediction",
    detail_level="detailed"  # or "medium", "brief"
)

# Personalize
user_ctx = {"name": "John", "interaction_count": 1}
personalized = engine.personalize_response(formatted, user_ctx)

# Progress indicator
progress = engine.generate_progress_indicator(step=3, total_steps=5, message="Processing")
# Output: [████████████░░░░░░░░] 60% - Processing

# Error handling
try:
    raise ConnectionError("Timeout")
except Exception as e:
    error_msg = engine.format_error_message(e, user_friendly=True)

# Contextual help
help_content = engine.get_contextual_help("prediction")
```

---

## 🔗 Complete Workflow Example

```python
def handle_user_request(user_input: str):
    """Complete workflow integrating all components."""
    
    # Initialize (do this once at startup)
    parser = TemporalExpressionParser()
    cps = ContextPreservationSystem()
    recognizer = IntentRecognizer()
    ux_engine = UXEnhancementEngine()
    coordinator = AgentCoordinationFramework()
    
    # Step 1: Recognize intent
    intent = recognizer.recognize_intent(user_input)
    
    # Step 2: Extract temporal information
    temporal = parser.extract_all_temporal(user_input)
    
    # Step 3: Get relevant context
    context = cps.get_relevant_context(user_input, max_items=5)
    
    # Step 4: Store in context
    cps.add_context(
        content=user_input,
        context_type="query",
        source="user",
        importance=0.7
    )
    
    # Step 5: Process based on intent
    if intent.primary_intent == "get_sports_prediction":
        # Call your prediction service
        result = {
            "sport": intent.parameters.get("sport", "Football"),
            "outcome": "Home Win",
            "confidence": 0.68,
            "reasoning": "Based on analysis",
            "factors": ["Form", "Head-to-head"],
            "recommendation": "Consider betting"
        }
        response_type = "prediction"
        
    elif intent.primary_intent == "get_team_analysis":
        result = {
            "subject": "Team Analysis",
            "key_finding": "Strong performance",
            "details": "Recent stats...",
            "recommendations": ["Continue current strategy"]
        }
        response_type = "analysis"
        
    else:
        result = {"message": "Processing your request..."}
        response_type = "information"
    
    # Step 6: Format response
    formatted = ux_engine.format_response(
        result,
        response_type=response_type,
        detail_level="medium"
    )
    
    # Step 7: Personalize
    user_ctx = {
        "name": "User",
        "interaction_count": len(cps.conversation_turns) + 1
    }
    personalized = ux_engine.personalize_response(formatted, user_ctx)
    
    # Step 8: Store conversation
    cps.add_conversation_turn(
        user_message=user_input,
        agent_response=personalized,
        intent=intent.primary_intent
    )
    
    return personalized
```

---

## 📊 Testing Commands

```bash
# Test individual modules
python tiannara_core/usability/temporal_parser.py
python tiannara_core/usability/context_preservation.py
python tiannara_core/usability/intent_recognition.py
python tiannara_core/usability/ux_enhancements.py
python tiannara_core/agents/coordination_framework.py

# Test integration
python -m tiannara_core.usability.test_integration
```

---

## 🎯 Common Use Cases

### Use Case 1: Sports Prediction with Context

```python
# User says: "Predict tomorrow's football match, I prefer detailed analysis"

intent = recognizer.recognize_intent("Predict tomorrow's football match")
temporal = parser.parse("tomorrow")

# Get user preference from context
prefs = cps.get_user_preferences()
detail_level = prefs.get("detail_level", "medium")

# Generate prediction
result = prediction_service.predict(
    sport="football",
    date=temporal.start_time
)

# Format with user's preferred detail level
formatted = ux_engine.format_response(result, "prediction", detail_level)
```

### Use Case 2: Multi-Agent Analysis

```python
# Complex task requiring multiple agents

task = framework.analyze_task_requirements(
    task_id="complex_analysis",
    description="Comprehensive team performance analysis",
    domain="sports_analysis",
    required_skills=["statistics", "pattern_recognition", "domain_knowledge"],
    complexity=TaskComplexity.COMPLEX,
    priority=8
)

# Select optimal agents
agents = framework.select_agents_for_task("complex_analysis")

# Collect agent outputs
agent_outputs = {}
for agent_id in agents:
    output = execute_agent_task(agent_id, task)
    agent_outputs[agent_id] = output

# Detect conflicts
conflicts = framework.detect_conflicts("complex_analysis", agent_outputs)

# Resolve conflicts
for conflict in conflicts:
    framework.resolve_conflict(conflict.conflict_id)

# Build consensus
consensus = framework.build_consensus(
    "complex_analysis",
    agent_votes={aid: out["conclusion"] for aid, out in agent_outputs.items()}
)
```

### Use Case 3: Conversational Flow

```python
# Maintain context across multiple turns

conversation = [
    "I'm interested in football predictions",
    "Specifically Premier League",
    "What about Manchester United's next match?"
]

for user_msg in conversation:
    # Recognize intent
    intent = recognizer.recognize_intent(user_msg)
    
    # Get context from previous turns
    context = cps.get_relevant_context(user_msg)
    
    # Process with context
    response = process_with_context(user_msg, intent, context)
    
    # Store in context
    cps.add_conversation_turn(
        user_message=user_msg,
        agent_response=response,
        intent=intent.primary_intent
    )
    
    print(response)
```

---

## ⚙️ Configuration Options

### Context Preservation

```python
cps = ContextPreservationSystem(
    max_short_term=50,      # Recent items
    max_medium_term=500,    # Session items
    max_long_term=5000,     # Persistent items
    decay_rate=0.95         # Relevance decay per hour
)
```

### UX Engine Preferences

```python
engine = UXEnhancementEngine()

# Set user preferences
engine.user_preferences = {
    "response_format": "markdown",  # or "plain_text", "json", "table"
    "detail_level": "medium",       # or "brief", "detailed"
    "language": "en",
    "timezone": "UTC",
    "accessibility_mode": False,
    "color_scheme": "light"
}
```

---

## 🐛 Troubleshooting

### Issue: Low Intent Confidence

```python
result = recognizer.recognize_intent(user_input)

if result.confidence < 0.6:
    # Ask for clarification
    print(f"I'm not sure I understand. {result.clarification_question}")
    
    # Or use fallback
    alternative_intent = get_alternative_interpretation(user_input)
```

### Issue: Context Not Found

```python
relevant = cps.get_relevant_context(query)

if not relevant:
    # Try broader query
    broader_query = extract_keywords(query)
    relevant = cps.get_relevant_context(broader_query, min_relevance=0.2)
```

### Issue: Temporal Parse Failed

```python
result = parser.parse(time_expression)

if result is None:
    # Try extracting from larger text
    results = parser.extract_all_temporal(full_text)
    if results:
        result = results[0]  # Use first match
    else:
        # Ask user to clarify
        print("When exactly? Please provide a specific date or time.")
```

---

## 📖 Documentation Links

- [Week 16 Complete Documentation](WEEK16_AGENT_COORDINATION_COMPLETE.md)
- [Weeks 17-20 Complete Documentation](WEEKS_17_20_USABILITY_COMPLETE.md)
- [Final Summary](WEEKS_16_20_FINAL_SUMMARY.md)

---

## 💡 Tips & Best Practices

1. **Always check confidence scores** before acting on intent recognition
2. **Set appropriate TTL** for time-sensitive context (e.g., 48 hours for match predictions)
3. **Use progressive disclosure** - start with brief, offer detailed on request
4. **Track statistics** to identify patterns and improve over time
5. **Personalize responses** based on interaction history
6. **Provide helpful errors** with solutions, not just messages
7. **Export context regularly** for long-running sessions
8. **Use weighted voting** in consensus based on agent performance

---

**Last Updated**: May 8, 2026  
**Version**: 1.0  
**Status**: Production Ready ✅
