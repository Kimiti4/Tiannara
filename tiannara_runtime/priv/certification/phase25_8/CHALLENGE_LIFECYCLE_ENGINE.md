# Challenge Lifecycle Engine

## Purpose
Manages the complete lifecycle of each discovery challenge from identification to resolution and permanent archiving.

## Lifecycle Stages

### 1. Identified
- Challenge detected from any source
- Registered in challenge registry
- Initial metadata recorded

### 2. Classified
- Domain, type, difficulty, urgency assigned
- Knowledge gap structured
- Prerequisites identified

### 3. Prioritized
- Value scores computed
- Urgency assessed
- Queue position assigned

### 4. Routed
- Scientific domain(s) assigned
- Engineering domain(s) assigned
- Research program(s) identified
- Capability requirements specified

### 5. In Progress
- Experimental or engineering work active
- Resources allocated
- Milestones tracked
- Intermediate results recorded

### 6. Under Review
- Results obtained
- Peer review (human or automated)
- Validation and replication

### 7. Solved
- Challenge resolved
- Discoveries recorded
- Engineering applications documented
- Evidence archived

### 8. Archived
- Permanent record maintained
- Challenge remains as scientific artifact
- Available for replay and archaeology

### Special States
- **Superseded**: challenge replaced by more precise formulation
- **Abandoned**: challenge deprioritized indefinitely (but never deleted)
- **Decomposed**: challenge split into sub-challenges

## Lifecycle Transitions
- Each transition recorded with timestamp, trigger, rationale, authorizing entity
- Transitions are replayable
- Rollback supported for incorrectly classified challenges
