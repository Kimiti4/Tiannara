# Ontology Visualization Model

## Purpose

The Ontology Visualization Model defines how concept birth, merge, split, retirement, evolution, semantic drift, replay, archaeology, and version trees are visualized in the Observatory.

## Ontology Evolution Visualization

### Evolution Timeline

#### Timeline View
- X-axis: Time
- Y-axis: Concept count
- Events: Concept birth, merge, split, retirement
- Interactive timeline with zoom

#### Event Markers
- Birth: Green circle
- Merge: Blue diamond
- Split: Orange triangle
- Retirement: Red square

### Evolution Flow

#### Sankey Diagram
- Flow of concepts through evolution
- Source: Parent concepts
- Target: Child concepts
- Width: Concept importance

#### Alluvial Diagram
- Similar to Sankey but with time axis
- Shows concept evolution over time
- Color by domain

## Concept Birth Visualization

### Birth Timeline
- Line chart of concept births over time
- X-axis: Time
- Y-axis: Birth count
- Multiple lines for different domains

### Birth Distribution
- Pie chart of births by domain
- Bar chart of births by creation date
- Heat map of births by importance

### Birth Detail View
- Concept name
- Definition
- Domain
- Parent concepts
- Evidence
- Timestamp
- Replay

## Concept Merge Visualization

### Merge Timeline
- Line chart of concept merges over time
- X-axis: Time
- Y-axis: Merge count

### Merge Distribution
- Pie chart of merges by domain
- Bar chart of merges by date

### Merge Detail View
- Source concepts
- Target concept
- Merge reason
- Evidence
- Timestamp
- Replay

### Merge Visualization
- Graph showing source concepts merging into target
- Color gradient from source to target
- Edge labels showing merge reason

## Concept Split Visualization

### Split Timeline
- Line chart of concept splits over time
- X-axis: Time
- Y-axis: Split count

### Split Distribution
- Pie chart of splits by domain
- Bar chart of splits by date

### Split Detail View
- Source concept
- Target concepts
- Split reason
- Evidence
- Timestamp
- Replay

### Split Visualization
- Graph showing source concept splitting into targets
- Color gradient from source to targets
- Edge labels showing split reason

## Concept Retirement Visualization

### Retirement Timeline
- Line chart of concept retirements over time
- X-axis: Time
- Y-axis: Retirement count

### Retirement Distribution
- Pie chart of retirements by domain
- Bar chart of retirements by date

### Retirement Detail View
- Concept name
- Retirement reason
- Evidence
- Timestamp
- Replay
- Successor concepts

### Retirement Visualization
- Graph showing concept retirement
- Concept shown as faded/gray
- Successor concepts highlighted

## Semantic Drift Visualization

### Drift Timeline
- Line chart of semantic drift over time
- X-axis: Time
- Y-axis: Drift score
- Multiple lines for different concepts

### Drift Heat Map
- Heat map of semantic drift
- X-axis: Time
- Y-axis: Concept
- Color: Drift magnitude

### Drift Detail View
- Concept name
- Drift score
- Drift direction
- Evidence
- Timestamp
- Replay

## Version Tree Visualization

### Tree View
- Hierarchical tree of concept versions
- Root: Original concept
- Children: Evolved versions
- Collapsible nodes

### Version Detail View
- Version ID
- Concept name
- Definition
- Changes from parent
- Timestamp
- Replay

### Version Comparison
- Side-by-side comparison of versions
- Diff highlighting
- Change summary

## Replay Visualization

### Replay Timeline
- Timeline of ontology replay
- Shows evolution steps
- Interactive playback

### Replay Animation
- Animated evolution of concepts
- Smooth transitions
- Play/pause/speed controls

### Replay Detail View
- Replay session ID
- Start timestamp
- End timestamp
- Steps
- Verification status

## Archaeology Visualization

### Archaeology Timeline
- Timeline of archaeology records
- Shows historical reconstruction
- Interactive exploration

### Archaeology Detail View
- Archaeology record ID
- Concept name
- Historical evidence
- Reconstruction quality
- Timestamp
- Replay

### Archaeology Comparison
- Comparison of historical vs current
- Shows evolution over time
- Change summary

## Interactive Features

### Zoom and Pan
- Zoom in/out on timeline
- Pan across timeline
- Reset view

### Filtering
- Filter by domain
- Filter by date range
- Filter by event type
- Filter by importance

### Searching
- Search for concepts
- Search for events
- Search by definition

### Export
- Export timeline as image
- Export data as JSON
- Export data as CSV

## Integration

The Ontology Visualization Model integrates with:
- Observatory Platform (visualization rendering)
- Metric Engine (metric queries)
- Time Series Engine (time series data)
- Storage Model (historical data)

## Acceptance Criteria

✓ Ontology evolution visualization
✓ Concept birth visualization
✓ Concept merge visualization
✓ Concept split visualization
✓ Concept retirement visualization
✓ Semantic drift visualization
✓ Version tree visualization
✓ Replay visualization
✓ Archaeology visualization
✓ Interactive features
