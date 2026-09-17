# Challenge Classification Engine

## Purpose
Classifies incoming challenges along multiple dimensions to enable appropriate routing and prioritization.

## Classification Dimensions

### Domain
- **Scientific**: physics, chemistry, biology, earth science, space science, neuroscience, mathematics, computer science
- **Engineering**: mechanical, electrical, civil, chemical, aerospace, materials, software, quantum
- **Planetary**: climate, ecology, water, food, energy, health, infrastructure
- **Civilizational**: governance, economics, ethics, security, space development

### Type
- **Unknown**: something not yet known
- **Bottleneck**: constraint preventing progress
- **Anomaly**: observation that doesn't fit current models
- **Opportunity**: new capability or approach
- **Problem**: practical challenge requiring solution

### Difficulty
- Trivial → Easy → Moderate → Hard → Very Hard → Open → Fundamental Limit
- Based on estimated resources, time, and prerequisite challenges

### Urgency
- Low → Medium → High → Critical
- Based on risk, resource depletion, or opportunity window

### Maturity
- **Identified**: just recognized
- **Formulated**: well-defined question
- **Approached**: methodology chosen
- **Evidence available**: partial data exists
- **Ready for experiment**: experimental approach designed
- **Ready for engineering**: solution known, needs implementation

## Classification Sources
- Automated classifiers using domain models
- Human expert classification
- Historical analogy (similar challenges classified previously)
- Ensemble: combine multiple classification signals
