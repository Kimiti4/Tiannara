"""
Temporal Reasoning Engine

Purpose: Advanced temporal reasoning and inference capabilities
Features:
- Temporal relationship detection (before, after, during, overlaps)
- Time inference from context
- Event timeline construction
- Temporal conflict detection
- Duration calculation and comparison
- Causal temporal chains
- Schedule optimization

Date: May 8, 2026
Status: Implementation Phase - Week 21 Day 1
"""

import re
from typing import Dict, List, Optional, Tuple, Set
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field


class TemporalRelation(Enum):
    """Types of temporal relationships between events."""
    BEFORE = "before"              # Event A occurs before Event B
    AFTER = "after"                # Event A occurs after Event B
    DURING = "during"              # Event A occurs during Event B
    OVERLAPS = "overlaps"          # Events overlap in time
    CONTAINS = "contains"          # Event A contains Event B
    STARTS = "starts"              # Event A starts when Event B starts
    ENDS = "ends"                  # Event A ends when Event B ends
    EQUALS = "equals"              # Events occur at same time
    MEETS = "meets"                # Event A ends when Event B starts
    MET_BY = "met_by"             # Event A starts when Event B ends


@dataclass
class TemporalEvent:
    """Represents an event with temporal information."""
    
    event_id: str
    name: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration: Optional[timedelta] = None
    metadata: Dict[str, any] = field(default_factory=dict)
    
    def get_duration(self) -> Optional[timedelta]:
        """Calculate or retrieve duration."""
        if self.duration:
            return self.duration
        elif self.start_time and self.end_time:
            return self.end_time - self.start_time
        return None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary."""
        return {
            "event_id": self.event_id,
            "name": self.name,
            "start_time": self.start_time.isoformat() if self.start_time else None,
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "duration_seconds": self.get_duration().total_seconds() if self.get_duration() else None
        }


@dataclass
class TemporalRelationship:
    """Represents a relationship between two events."""
    
    event_a_id: str
    event_b_id: str
    relation: TemporalRelation
    confidence: float = 1.0
    evidence: str = ""
    
    def to_dict(self) -> Dict:
        return {
            "event_a": self.event_a_id,
            "event_b": self.event_b_id,
            "relation": self.relation.value,
            "confidence": self.confidence,
            "evidence": self.evidence
        }


@dataclass
class Timeline:
    """Chronological sequence of events."""
    
    events: List[TemporalEvent] = field(default_factory=list)
    conflicts: List[str] = field(default_factory=list)
    gaps: List[Tuple[datetime, datetime]] = field(default_factory=list)
    
    def add_event(self, event: TemporalEvent):
        """Add event and maintain chronological order."""
        self.events.append(event)
        self.events.sort(key=lambda e: e.start_time or datetime.min)
    
    def detect_conflicts(self) -> List[str]:
        """Detect overlapping events that shouldn't overlap."""
        conflicts = []
        
        for i in range(len(self.events)):
            for j in range(i + 1, len(self.events)):
                event_a = self.events[i]
                event_b = self.events[j]
                
                # Skip if either event has no time info
                if not event_a.start_time or not event_b.start_time:
                    continue
                
                # Check for overlap
                if self._events_overlap(event_a, event_b):
                    conflicts.append(
                        f"Conflict: '{event_a.name}' overlaps with '{event_b.name}'"
                    )
        
        self.conflicts = conflicts
        return conflicts
    
    def find_gaps(self, min_gap_duration: timedelta = timedelta(hours=1)) -> List[Tuple[datetime, datetime]]:
        """Find gaps between consecutive events."""
        gaps = []
        
        for i in range(len(self.events) - 1):
            current = self.events[i]
            next_event = self.events[i + 1]
            
            if current.end_time and next_event.start_time:
                gap_start = current.end_time
                gap_end = next_event.start_time
                gap_duration = gap_end - gap_start
                
                if gap_duration >= min_gap_duration:
                    gaps.append((gap_start, gap_end))
        
        self.gaps = gaps
        return gaps
    
    def _events_overlap(self, event_a: TemporalEvent, event_b: TemporalEvent) -> bool:
        """Check if two events overlap in time."""
        if not event_a.start_time or not event_b.start_time:
            return False
        
        # Get effective end times
        a_end = event_a.end_time or (event_a.start_time + (event_a.get_duration() or timedelta(hours=1)))
        b_end = event_b.end_time or (event_b.start_time + (event_b.get_duration() or timedelta(hours=1)))
        
        # Check overlap
        return event_a.start_time < b_end and event_b.start_time < a_end
    
    def to_dict(self) -> Dict:
        return {
            "events": [e.to_dict() for e in self.events],
            "conflicts": self.conflicts,
            "gaps": [(s.isoformat(), e.isoformat()) for s, e in self.gaps]
        }


class TemporalReasoningEngine:
    """
    Advanced temporal reasoning engine for understanding time relationships.
    
    Capabilities:
    - Detect temporal relationships between events
    - Infer implicit temporal information
    - Build and analyze timelines
    - Detect scheduling conflicts
    - Calculate time differences and projections
    - Identify causal temporal chains
    """
    
    def __init__(self):
        self.events: Dict[str, TemporalEvent] = {}
        self.relationships: List[TemporalRelationship] = []
        self.timelines: Dict[str, Timeline] = {}
        
        # Statistics
        self.stats = {
            "events_processed": 0,
            "relationships_detected": 0,
            "conflicts_found": 0,
            "inferences_made": 0
        }
    
    def add_event(self, event: TemporalEvent):
        """Register an event for reasoning."""
        self.events[event.event_id] = event
        self.stats["events_processed"] += 1
    
    def detect_relationship(self, event_a_id: str, event_b_id: str) -> Optional[TemporalRelationship]:
        """
        Detect temporal relationship between two events.
        
        Uses Allen's Interval Algebra for comprehensive relationship detection.
        
        Returns:
            TemporalRelationship or None if cannot determine
        """
        if event_a_id not in self.events or event_b_id not in self.events:
            return None
        
        event_a = self.events[event_a_id]
        event_b = self.events[event_b_id]
        
        # Need at least start times for both events
        if not event_a.start_time or not event_b.start_time:
            return None
        
        # Get effective end times
        a_end = event_a.end_time or (event_a.start_time + (event_a.get_duration() or timedelta(hours=1)))
        b_end = event_b.end_time or (event_b.start_time + (event_b.get_duration() or timedelta(hours=1)))
        
        # Determine relationship using interval algebra
        relation = self._classify_interval_relation(
            event_a.start_time, a_end,
            event_b.start_time, b_end
        )
        
        if relation:
            relationship = TemporalRelationship(
                event_a_id=event_a_id,
                event_b_id=event_b_id,
                relation=relation,
                confidence=0.9
            )
            self.relationships.append(relationship)
            self.stats["relationships_detected"] += 1
            return relationship
        
        return None
    
    def infer_implicit_time(self, 
                           reference_event_id: str,
                           temporal_expression: str) -> Optional[datetime]:
        """
        Infer implicit time based on reference event and expression.
        
        Examples:
        - "the day after" reference → reference + 1 day
        - "two weeks before" reference → reference - 14 days
        - "the following month" reference → reference + 1 month
        
        Args:
            reference_event_id: Reference event ID
            temporal_expression: Natural language temporal expression
            
        Returns:
            Inferred datetime or None
        """
        if reference_event_id not in self.events:
            return None
        
        reference = self.events[reference_event_id]
        if not reference.start_time:
            return None
        
        ref_time = reference.start_time
        
        # Parse temporal expression
        inferred_time = self._parse_temporal_offset(ref_time, temporal_expression)
        
        if inferred_time:
            self.stats["inferences_made"] += 1
        
        return inferred_time
    
    def build_timeline(self, 
                      event_ids: List[str],
                      timeline_name: str = "default") -> Timeline:
        """
        Build chronological timeline from events.
        
        Args:
            event_ids: List of event IDs to include
            timeline_name: Name for the timeline
            
        Returns:
            Timeline object with sorted events
        """
        timeline = Timeline()
        
        for event_id in event_ids:
            if event_id in self.events:
                timeline.add_event(self.events[event_id])
        
        # Detect conflicts and gaps
        timeline.detect_conflicts()
        timeline.find_gaps()
        
        self.timelines[timeline_name] = timeline
        
        if timeline.conflicts:
            self.stats["conflicts_found"] += len(timeline.conflicts)
        
        return timeline
    
    def calculate_time_difference(self, 
                                 event_a_id: str,
                                 event_b_id: str) -> Optional[timedelta]:
        """
        Calculate time difference between two events.
        
        Returns:
            Timedelta (positive if B is after A, negative if before)
        """
        if event_a_id not in self.events or event_b_id not in self.events:
            return None
        
        event_a = self.events[event_a_id]
        event_b = self.events[event_b_id]
        
        if not event_a.start_time or not event_b.start_time:
            return None
        
        return event_b.start_time - event_a.start_time
    
    def find_events_in_range(self, 
                            start: datetime,
                            end: datetime) -> List[TemporalEvent]:
        """Find all events occurring within a time range."""
        matching_events = []
        
        for event in self.events.values():
            if not event.start_time:
                continue
            
            event_end = event.end_time or (event.start_time + (event.get_duration() or timedelta(hours=1)))
            
            # Check if event overlaps with range
            if event.start_time < end and event_end > start:
                matching_events.append(event)
        
        return matching_events
    
    def detect_causal_chain(self, 
                           event_sequence: List[str]) -> List[TemporalRelationship]:
        """
        Detect potential causal relationships in event sequence.
        
        Assumes events in sequence might have causal relationships
        if they occur in temporal order with reasonable gaps.
        
        Args:
            event_sequence: Ordered list of event IDs
            
        Returns:
            List of detected causal relationships
        """
        causal_relationships = []
        max_causal_gap = timedelta(days=7)  # Events more than 7 days apart unlikely causal
        
        for i in range(len(event_sequence) - 1):
            current_id = event_sequence[i]
            next_id = event_sequence[i + 1]
            
            if current_id not in self.events or next_id not in self.events:
                continue
            
            current = self.events[current_id]
            next_event = self.events[next_id]
            
            if not current.start_time or not next_event.start_time:
                continue
            
            time_diff = next_event.start_time - current.start_time
            
            # Check if within causal window and in correct order
            if timedelta(0) <= time_diff <= max_causal_gap:
                relationship = TemporalRelationship(
                    event_a_id=current_id,
                    event_b_id=next_id,
                    relation=TemporalRelation.BEFORE,
                    confidence=0.7,  # Lower confidence for inferred causality
                    evidence=f"Temporal proximity: {time_diff}"
                )
                causal_relationships.append(relationship)
        
        return causal_relationships
    
    def optimize_schedule(self, 
                         event_ids: List[str],
                         constraints: Dict[str, any] = None) -> List[str]:
        """
        Optimize event schedule to minimize conflicts and gaps.
        
        Args:
            event_ids: Events to schedule
            constraints: Scheduling constraints (min_gap, working_hours, etc.)
            
        Returns:
            Optimized ordering of event IDs
        """
        constraints = constraints or {}
        min_gap = constraints.get("min_gap", timedelta(minutes=30))
        
        # Simple greedy optimization: sort by start time, adjust to avoid conflicts
        events_to_schedule = [
            self.events[eid] for eid in event_ids 
            if eid in self.events and self.events[eid].start_time
        ]
        
        events_to_schedule.sort(key=lambda e: e.start_time)
        
        optimized_order = []
        current_time = None
        
        for event in events_to_schedule:
            if current_time and event.start_time < current_time:
                # Would conflict, skip for now (could reschedule)
                continue
            
            optimized_order.append(event.event_id)
            event_duration = event.get_duration() or timedelta(hours=1)
            current_time = event.start_time + event_duration + min_gap
        
        return optimized_order
    
    def get_reasoning_stats(self) -> Dict:
        """Get temporal reasoning statistics."""
        return {
            **self.stats,
            "total_events": len(self.events),
            "total_relationships": len(self.relationships),
            "total_timelines": len(self.timelines)
        }
    
    # Private helper methods
    
    def _classify_interval_relation(self, 
                                   a_start: datetime, a_end: datetime,
                                   b_start: datetime, b_end: datetime) -> Optional[TemporalRelation]:
        """Classify relationship using Allen's Interval Algebra."""
        
        # Check for equality
        if a_start == b_start and a_end == b_end:
            return TemporalRelation.EQUALS
        
        # Check if A before B
        if a_end <= b_start:
            if a_end == b_start:
                return TemporalRelation.MEETS
            return TemporalRelation.BEFORE
        
        # Check if A after B
        if a_start >= b_end:
            if a_start == b_end:
                return TemporalRelation.MET_BY
            return TemporalRelation.AFTER
        
        # Check if A during B
        if a_start >= b_start and a_end <= b_end:
            if a_start == b_start and a_end == b_end:
                return TemporalRelation.EQUALS
            elif a_start == b_start:
                return TemporalRelation.STARTS
            elif a_end == b_end:
                return TemporalRelation.ENDS
            return TemporalRelation.DURING
        
        # Check if A contains B
        if a_start <= b_start and a_end >= b_end:
            return TemporalRelation.CONTAINS
        
        # Check overlap
        if a_start < b_end and b_start < a_end:
            return TemporalRelation.OVERLAPS
        
        return None
    
    def _parse_temporal_offset(self, 
                              reference: datetime,
                              expression: str) -> Optional[datetime]:
        """Parse natural language temporal offset expression."""
        expression_lower = expression.lower()
        
        # Days offset
        days_match = re.search(r'(\d+)\s*days?\s*(after|before|later|ago)', expression_lower)
        if days_match:
            days = int(days_match.group(1))
            direction = days_match.group(2)
            
            if direction in ["after", "later"]:
                return reference + timedelta(days=days)
            else:  # before, ago
                return reference - timedelta(days=days)
        
        # Weeks offset
        weeks_match = re.search(r'(\d+)\s*weeks?\s*(after|before|later|ago)', expression_lower)
        if weeks_match:
            weeks = int(weeks_match.group(1))
            direction = weeks_match.group(2)
            
            if direction in ["after", "later"]:
                return reference + timedelta(weeks=weeks)
            else:
                return reference - timedelta(weeks=weeks)
        
        # Simple expressions
        if "tomorrow" in expression_lower or "next day" in expression_lower:
            return reference + timedelta(days=1)
        elif "yesterday" in expression_lower or "previous day" in expression_lower:
            return reference - timedelta(days=1)
        elif "next week" in expression_lower:
            return reference + timedelta(weeks=1)
        elif "last week" in expression_lower:
            return reference - timedelta(weeks=1)
        elif "next month" in expression_lower:
            # Approximate: add 30 days
            return reference + timedelta(days=30)
        elif "last month" in expression_lower:
            return reference - timedelta(days=30)
        
        return None


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("TEMPORAL REASONING ENGINE - TEST")
    print("="*70)
    
    engine = TemporalReasoningEngine()
    
    # Create test events
    print("\n📅 Creating test events...")
    
    base_time = datetime(2026, 5, 8, 10, 0)  # May 8, 2026, 10:00 AM
    
    events = [
        TemporalEvent(
            event_id="evt_001",
            name="Team Meeting",
            start_time=base_time,
            end_time=base_time + timedelta(hours=1)
        ),
        TemporalEvent(
            event_id="evt_002",
            name="Lunch Break",
            start_time=base_time + timedelta(hours=2),
            end_time=base_time + timedelta(hours=3)
        ),
        TemporalEvent(
            event_id="evt_003",
            name="Project Review",
            start_time=base_time + timedelta(hours=1, minutes=30),  # Overlaps with lunch
            end_time=base_time + timedelta(hours=2, minutes=30)
        ),
        TemporalEvent(
            event_id="evt_004",
            name="Training Session",
            start_time=base_time + timedelta(days=1),  # Next day
            duration=timedelta(hours=2)
        ),
        TemporalEvent(
            event_id="evt_005",
            name="Follow-up Meeting",
            start_time=base_time + timedelta(days=2),  # Two days later
            end_time=base_time + timedelta(days=2, hours=1)
        )
    ]
    
    for event in events:
        engine.add_event(event)
        print(f"  ✓ Added: {event.name} ({event.start_time.strftime('%Y-%m-%d %H:%M')})")
    
    print(f"\n✅ Registered {len(events)} events")
    
    # Test 1: Detect relationships
    print("\n🔗 Test 1: Detecting Temporal Relationships")
    print("-" * 70)
    
    relationships_to_check = [
        ("evt_001", "evt_002"),
        ("evt_001", "evt_003"),
        ("evt_002", "evt_003"),
        ("evt_001", "evt_004"),
        ("evt_004", "evt_005")
    ]
    
    for evt_a, evt_b in relationships_to_check:
        rel = engine.detect_relationship(evt_a, evt_b)
        if rel:
            event_a_name = engine.events[evt_a].name
            event_b_name = engine.events[evt_b].name
            print(f"  {event_a_name} → {event_b_name}: {rel.relation.value} ({rel.confidence:.0%})")
    
    # Test 2: Infer implicit times
    print("\n🧠 Test 2: Inferring Implicit Times")
    print("-" * 70)
    
    inferences = [
        ("evt_001", "the day after"),
        ("evt_001", "2 days later"),
        ("evt_004", "1 week before"),
        ("evt_001", "tomorrow")
    ]
    
    for evt_id, expression in inferences:
        inferred = engine.infer_implicit_time(evt_id, expression)
        if inferred:
            event_name = engine.events[evt_id].name
            print(f"  '{expression}' after {event_name}: {inferred.strftime('%Y-%m-%d %H:%M')}")
    
    # Test 3: Build timeline
    print("\n📊 Test 3: Building Timeline")
    print("-" * 70)
    
    timeline = engine.build_timeline(
        ["evt_001", "evt_002", "evt_003", "evt_004"],
        "daily_schedule"
    )
    
    print(f"Timeline: {len(timeline.events)} events")
    for i, event in enumerate(timeline.events, 1):
        print(f"  {i}. {event.name}")
        start_str = event.start_time.strftime('%H:%M') if event.start_time else "N/A"
        end_str = event.end_time.strftime('%H:%M') if event.end_time else "N/A"
        print(f"     {start_str} - {end_str}")
    
    # Test 4: Detect conflicts
    print("\n⚠️  Test 4: Conflict Detection")
    print("-" * 70)
    
    conflicts = timeline.detect_conflicts()
    if conflicts:
        print(f"Found {len(conflicts)} conflict(s):")
        for conflict in conflicts:
            print(f"  ⚠️  {conflict}")
    else:
        print("  ✓ No conflicts detected")
    
    # Test 5: Find gaps
    print("\n🕐 Test 5: Gap Analysis")
    print("-" * 70)
    
    gaps = timeline.find_gaps(min_gap_duration=timedelta(minutes=30))
    if gaps:
        print(f"Found {len(gaps)} gap(s):")
        for start, end in gaps:
            gap_duration = end - start
            print(f"  • {start.strftime('%H:%M')} - {end.strftime('%H:%M')} ({gap_duration})")
    else:
        print("  ✓ No significant gaps")
    
    # Test 6: Calculate time differences
    print("\n⏱️  Test 6: Time Difference Calculations")
    print("-" * 70)
    
    diff_pairs = [
        ("evt_001", "evt_002"),
        ("evt_001", "evt_004"),
        ("evt_004", "evt_005")
    ]
    
    for evt_a, evt_b in diff_pairs:
        diff = engine.calculate_time_difference(evt_a, evt_b)
        if diff:
            event_a_name = engine.events[evt_a].name
            event_b_name = engine.events[evt_b].name
            hours = diff.total_seconds() / 3600
            print(f"  {event_a_name} → {event_b_name}: {hours:.1f} hours")
    
    # Test 7: Causal chain detection
    print("\n🔗 Test 7: Causal Chain Detection")
    print("-" * 70)
    
    causal_chain = engine.detect_causal_chain(["evt_001", "evt_004", "evt_005"])
    if causal_chain:
        print(f"Detected {len(causal_chain)} potential causal relationship(s):")
        for rel in causal_chain:
            event_a = engine.events[rel.event_a_id].name
            event_b = engine.events[rel.event_b_id].name
            print(f"  {event_a} → {event_b} (confidence: {rel.confidence:.0%})")
    else:
        print("  No causal relationships detected")
    
    # Test 8: Schedule optimization
    print("\n📋 Test 8: Schedule Optimization")
    print("-" * 70)
    
    optimized = engine.optimize_schedule(
        ["evt_001", "evt_002", "evt_003", "evt_004"],
        constraints={"min_gap": timedelta(minutes=15)}
    )
    
    print("Optimized order:")
    for i, evt_id in enumerate(optimized, 1):
        event = engine.events[evt_id]
        print(f"  {i}. {event.name} ({event.start_time.strftime('%H:%M')})")
    
    # Show statistics
    print("\n📈 Temporal Reasoning Statistics:")
    print("-" * 70)
    stats = engine.get_reasoning_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")
    
    print("\n" + "="*70)
    print("✅ TEMPORAL REASONING ENGINE TEST COMPLETE")
    print("="*70)
