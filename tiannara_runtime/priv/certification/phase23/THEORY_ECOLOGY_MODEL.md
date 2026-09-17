# Theory Ecology Model

## Purpose

The Theory Ecology Model defines how theories are represented as evolving organisms in the Observatory, visualizing prediction success, evidence, competition, replacement, dominance, utility, engineering impact, and theory lifespan.

## Theory as Organism

### Organism Metaphor

#### Theory as Living Entity
- **Size**: Represents evidence strength
- **Color**: Represents prediction success rate
- **Shape**: Represents theory type
- **Movement**: Represents evolution over time
- **Lifespan**: Represents theory longevity

#### Theory Organism Attributes
```
theory_organism: {
  theory_id: string,
  theory_name: string,
  size: float,  # evidence strength
  color: string,  # prediction success
  shape: string,  # theory type
  position: {x, y},
  velocity: {vx, vy},
  lifespan: integer,
  health: float
}
```

## Theory Ecology Visualization

### Ecology View

#### Organism Display
- Theories shown as organisms
- Size: Evidence strength (larger = more evidence)
- Color: Prediction success (green = high, red = low)
- Shape: Theory type (circle = general, square = specific)

#### Interaction Display
- Competition: Organisms pushing apart
- Cooperation: Organisms clustering together
- Replacement: Old organism fading, new organism appearing
- Dominance: Large organism with smaller organisms around

### Organism Attributes

#### Size (Evidence Strength)
- Small: < 10 evidence records
- Medium: 10-100 evidence records
- Large: > 100 evidence records

#### Color (Prediction Success)
- Green: > 90% success
- Yellow: 70-90% success
- Orange: 50-70% success
- Red: < 50% success

#### Shape (Theory Type)
- Circle: General theory
- Square: Specific theory
- Triangle: Mathematical theory
- Diamond: Engineering theory

## Prediction Success Visualization

### Success Rate Timeline
- Line chart of prediction success over time
- X-axis: Time
- Y-axis: Success rate (0-1)
- Multiple lines for different theories

### Success Distribution
- Histogram of prediction success rates
- X-axis: Success rate
- Y-axis: Frequency

### Success Heat Map
- Heat map of prediction success
- X-axis: Time
- Y-axis: Theory
- Color: Success rate

## Evidence Visualization

### Evidence Timeline
- Line chart of evidence accumulation over time
- X-axis: Time
- Y-axis: Evidence count
- Multiple lines for different theories

### Evidence Distribution
- Histogram of evidence counts
- X-axis: Evidence count
- Y-axis: Frequency

### Evidence Strength
- Bar chart of evidence strength by theory
- X-axis: Theory
- Y-axis: Evidence strength

## Competition Visualization

### Competition Graph
- Network graph of theory competition
- Nodes: Theories
- Edges: Competition relationships
- Edge width: Competition intensity

### Competition Timeline
- Timeline of competition events
- Shows when theories compete
- Interactive exploration

### Competition Matrix
- Matrix showing competition between theories
- X-axis: Theory
- Y-axis: Theory
- Cell: Competition intensity

## Replacement Visualization

### Replacement Timeline
- Timeline of theory replacements
- Shows when theories replace each other
- Interactive exploration

### Replacement Flow
- Sankey diagram of theory replacement flow
- Source: Old theories
- Target: New theories
- Width: Replacement frequency

### Replacement Detail View
- Old theory name
- New theory name
- Replacement reason
- Evidence
- Timestamp
- Replay

## Dominance Visualization

### Dominance Timeline
- Line chart of theory dominance over time
- X-axis: Time
- Y-axis: Dominance score
- Multiple lines for different theories

### Dominance Distribution
- Pie chart of dominance by theory
- Shows which theories dominate

### Dominance Heat Map
- Heat map of theory dominance
- X-axis: Time
- Y-axis: Theory
- Color: Dominance score

## Utility Visualization

### Utility Timeline
- Line chart of theory utility over time
- X-axis: Time
- Y-axis: Utility score
- Multiple lines for different theories

### Utility Distribution
- Histogram of utility scores
- X-axis: Utility score
- Y-axis: Frequency

### Utility by Domain
- Bar chart of utility by domain
- X-axis: Domain
- Y-axis: Utility score

## Engineering Impact Visualization

### Impact Timeline
- Line chart of engineering impact over time
- X-axis: Time
- Y-axis: Impact score
- Multiple lines for different theories

### Impact Distribution
- Histogram of impact scores
- X-axis: Impact score
- Y-axis: Frequency

### Impact by Domain
- Bar chart of impact by domain
- X-axis: Domain
- Y-axis: Impact score

## Theory Lifespan Visualization

### Lifespan Timeline
- Timeline of theory lifespans
- Shows when theories are born and die
- Interactive exploration

### Lifespan Distribution
- Histogram of theory lifespans
- X-axis: Lifespan
- Y-axis: Frequency

### Lifespan by Domain
- Bar chart of lifespan by domain
- X-axis: Domain
- Y-axis: Average lifespan

## Interactive Features

### Zoom and Pan
- Zoom in/out on ecology view
- Pan across ecology view
- Reset view

### Filtering
- Filter by domain
- Filter by date range
- Filter by success rate
- Filter by evidence strength

### Searching
- Search for theories
- Search by name
- Search by definition

### Organism Selection
- Click on organism to see details
- Highlight related organisms
- Show history

### Export
- Export ecology as image
- Export data as JSON
- Export data as CSV

## Integration

The Theory Ecology Model integrates with:
- Observatory Platform (visualization rendering)
- Metric Engine (metric queries)
- Time Series Engine (time series data)
- Storage Model (historical data)

## Acceptance Criteria

✓ Theory as organism representation
✓ Prediction success visualization
✓ Evidence visualization
✓ Competition visualization
✓ Replacement visualization
✓ Dominance visualization
✓ Utility visualization
✓ Engineering impact visualization
✓ Theory lifespan visualization
✓ Interactive features
