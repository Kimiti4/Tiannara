# Evolutionary Campaign Plan

## Campaign Parameters
- **Projects**: Project A, Project B, Project C, Project D, Project E
- **Generations**: 20 per project
- **Observation Density**: 10 scenarios per generation
- **Total Expected Observations**: 1,000 (5 projects * 20 generations * 10 scenarios)

## Adaptation Metrics Implementation
- **Adaptation Velocity**: Calculate fitness change between generations.
- **Recovery Half-Life**: Measure time to recover 50% of lost fitness.
- **Failure Recurrence Rate**: Track repeated failure patterns after repair.
- **Repair Transferability**: Test whether repairs discovered in one project work in another.

## Todo List
- [x] Define campaign parameters (projects, generations, etc.)
- [x] Select 5 projects for the evolutionary campaign
- [x] Set up generation loop (20 generations per project)
- [x] Configure observation density (10 scenarios per generation)
- [ ] Implement adaptation metrics (adaptation velocity, recovery half-life, etc.)
- [ ] Run the evolutionary campaign
- [ ] Collect and analyze observations
- [ ] Perform law discovery
- [ ] Validate candidate laws
- [ ] Document findings
