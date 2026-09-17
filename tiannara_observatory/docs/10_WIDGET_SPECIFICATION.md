# Widget Specification Standard

## Overview

A widget is a certified visualization component. Widgets are not merely React components — they are versioned, replayable, auditable data products with formally declared inputs, refresh policies, and certification requirements.

---

## Widget Schema

```json
{
  "widget_id": "string (UUID v7)",
  "spec_version": "string (semver)",
  "name": "string",
  "description": "string",
  "owner": "string (domain/owner)",

  "data_sources": [
    {
      "type": "metric | event_stream | snapshot | replay | api_endpoint",
      "uri": "string (data source URI)",
      "fields": ["string"],
      "aggregation": "raw | 1s | 5s | 30s | 5m | 1h | 24h",
      "filters": {}
    }
  ],

  "refresh_policy": {
    "mode": "poll | push | manual | event_driven",
    "interval_ms": "integer (for poll mode)",
    "staleness_threshold_ms": "integer"
  },

  "replay_compatibility": {
    "replayable": true | false,
    "historical_data_source": "string (replay query URI)",
    "replay_accuracy": "exact | approximate | not_supported"
  },

  "certification_requirements": {
    "minimum_status": "certified | provisional | degraded | stale | uncertain",
    "certification_domains": ["string"],
    "show_unmet_behaviour": "hidden | greyed | warning_banner"
  },

  "security_classification": {
    "minimum_clearance": "public | internal | restricted | secret | constitutional",
    "compartments": ["string"]
  },

  "interaction_policy": {
    "clickable": true | false,
    "zoomable": true | false,
    "exportable": true | false,
    "annotatable": true | false,
    "max_refresh_rate_ms": "integer"
  },

  "visualization": {
    "type": "line | bar | gauge | table | heatmap | scatter | sankey | radar | custom",
    "library": "recharts | d3 | chart.js | custom",
    "options": {}
  },

  "size": {
    "min_width": "integer (grid units, 1 unit = 100px)",
    "min_height": "integer",
    "default_width": "integer",
    "default_height": "integer",
    "resizable": true | false
  }
}
```

---

## Built-in Widget Types

| Type | Description | Default Size | Replayable |
|------|-------------|-------------|------------|
| `line_chart` | Time-series line chart | 4×3 | Yes |
| `bar_chart` | Categorical or temporal bar chart | 4×3 | Yes |
| `gauge` | Single-value gauge with threshold zones | 2×2 | Yes |
| `metric_card` | Single metric value with sparkline | 2×1 | Yes |
| `table` | Data table with sort/filter | 6×4 | Yes |
| `heatmap` | 2D intensity grid | 4×3 | Yes |
| `scatter_plot` | XY scatter with optional grouping | 4×3 | Yes |
| `sankey` | Flow diagram | 6×4 | Yes |
| `radar` | Multi-axis comparison | 4×4 | Yes |
| `event_log` | Scrollable event stream | 6×3 | Yes |
| `status_grid` | Grid of subsystem health indicators | 4×2 | Yes |
| `alert_list` | Active alerts with severity coloring | 4×3 | Yes |
| `replay_control` | Historical timestamp scrubber | 6×1 | N/A (is the control) |
| `certification_tree` | Certification status propagation tree | 4×4 | Yes |

---

## Widget Lifecycle

```
1. REGISTERED
   - Widget spec is registered in the Widget Registry
   - Not yet instantiated on any dashboard

2. INSTANTIATED
   - Widget is placed on a dashboard
   - Receives configuration (data source parameters, visual options)
   - Begins loading data

3. LOADING
   - Widget is fetching data
   - Shows placeholder/skeleton state

4. RENDERING
   - Data received, certification checked
   - If minimum_certification_status is met: render normally
   - If not met: render degraded state (greyed, warning)

5. STALE
   - Data is older than staleness_threshold_ms
   - Widget shows visual indicator of staleness
   - If stale exceeds 2× threshold: transitions to FAILED

6. FAILED
   - Data source unreachable or certification invalidated
   - Widget shows error state with reason

7. REMOVED
   - Widget is removed from dashboard
   - Spec remains in registry
```

## Widget Registration Guarantees

| Guarantee | Description |
|-----------|-------------|
| **Deterministic Rendering** | Same widget spec + same event stream at same timestamp produces identical rendered output. |
| **Certification Transparency** | Widget shows its certification status and the status of its data sources. |
| **Replay Compatibility** | All widgets must support replay unless explicitly marked as `replayable: false`. |
| **No Hidden Data** | Widgets never silently omit data. Filtering is declared in the spec. |
| **Versioning** | Widget spec changes produce a new spec version. Old versions remain renderable. |
