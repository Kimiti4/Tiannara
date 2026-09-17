"""
Temporal Expression Parser

Purpose: Parse and understand natural language time expressions
Features:
- Relative time parsing (e.g., "next week", "3 days ago")
- Absolute time parsing (e.g., "January 15, 2026")
- Duration parsing (e.g., "for 2 hours", "over 6 months")
- Recurring event detection (e.g., "every Monday", "monthly")
- Time range parsing (e.g., "from Monday to Friday")
- Fuzzy time expressions (e.g., "soon", "recently", "a while back")
- Multi-language support foundation

Date: May 8, 2026
Status: Implementation Phase - Week 17
"""

import re
from typing import Dict, List, Optional, Tuple, Union
from datetime import datetime, timedelta
from enum import Enum


class TemporalType(Enum):
    """Types of temporal expressions."""
    ABSOLUTE = "absolute"           # Specific date/time
    RELATIVE = "relative"           # Relative to now
    DURATION = "duration"           # Time span
    RECURRING = "recurring"         # Repeating pattern
    RANGE = "range"                # Time range
    FUZZY = "fuzzy"                # Imprecise time


class ParsedTime:
    """Represents a parsed temporal expression."""
    
    def __init__(self,
                 original_text: str,
                 time_type: TemporalType,
                 start_time: Optional[datetime] = None,
                 end_time: Optional[datetime] = None,
                 duration: Optional[timedelta] = None,
                 recurrence_pattern: Optional[str] = None,
                 confidence: float = 1.0):
        self.original_text = original_text
        self.time_type = time_type
        self.start_time = start_time
        self.end_time = end_time
        self.duration = duration
        self.recurrence_pattern = recurrence_pattern
        self.confidence = confidence
        
    def to_dict(self) -> Dict:
        """Convert to dictionary representation."""
        return {
            "original_text": self.original_text,
            "type": self.time_type.value,
            "start_time": self.start_time.isoformat() if self.start_time else None,
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "duration_seconds": self.duration.total_seconds() if self.duration else None,
            "recurrence_pattern": self.recurrence_pattern,
            "confidence": self.confidence
        }


class TemporalExpressionParser:
    """
    Advanced temporal expression parser for natural language understanding.
    
    Supports:
    - Relative time expressions ("tomorrow", "next week", "3 days ago")
    - Absolute dates ("January 15, 2026", "2026-01-15")
    - Durations ("for 2 hours", "over 6 months")
    - Recurring patterns ("every Monday", "monthly")
    - Time ranges ("from Monday to Friday")
    - Fuzzy expressions ("soon", "recently")
    """
    
    def __init__(self, reference_time: Optional[datetime] = None):
        self.reference_time = reference_time or datetime.now()
        
        # Compile regex patterns for efficiency
        self._compile_patterns()
        
    def _compile_patterns(self):
        """Compile regex patterns for temporal expression matching."""
        
        # Relative time patterns
        self.relative_patterns = {
            'today': re.compile(r'\btoday\b', re.IGNORECASE),
            'tomorrow': re.compile(r'\btomorrow\b', re.IGNORECASE),
            'yesterday': re.compile(r'\byesterday\b', re.IGNORECASE),
            'next_week': re.compile(r'\bnext\s+week\b', re.IGNORECASE),
            'last_week': re.compile(r'\blast\s+week\b', re.IGNORECASE),
            'next_month': re.compile(r'\bnext\s+month\b', re.IGNORECASE),
            'last_month': re.compile(r'\blast\s+month\b', re.IGNORECASE),
            'next_year': re.compile(r'\bnext\s+year\b', re.IGNORECASE),
            'last_year': re.compile(r'\blast\s+year\b', re.IGNORECASE),
            'days_ago': re.compile(r'(\d+)\s+days?\s+ago', re.IGNORECASE),
            'weeks_ago': re.compile(r'(\d+)\s+weeks?\s+ago', re.IGNORECASE),
            'months_ago': re.compile(r'(\d+)\s+months?\s+ago', re.IGNORECASE),
            'years_ago': re.compile(r'(\d+)\s+years?\s+ago', re.IGNORECASE),
            'in_days': re.compile(r'in\s+(\d+)\s+days?', re.IGNORECASE),
            'in_weeks': re.compile(r'in\s+(\d+)\s+weeks?', re.IGNORECASE),
            'in_months': re.compile(r'in\s+(\d+)\s+months?', re.IGNORECASE),
            'in_years': re.compile(r'in\s+(\d+)\s+years?', re.IGNORECASE),
        }
        
        # Duration patterns
        self.duration_patterns = {
            'hours': re.compile(r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?)', re.IGNORECASE),
            'days': re.compile(r'(\d+(?:\.\d+)?)\s*days?', re.IGNORECASE),
            'weeks': re.compile(r'(\d+(?:\.\d+)?)\s*weeks?', re.IGNORECASE),
            'months': re.compile(r'(\d+(?:\.\d+)?)\s*months?', re.IGNORECASE),
            'years': re.compile(r'(\d+(?:\.\d+)?)\s*years?', re.IGNORECASE),
            'minutes': re.compile(r'(\d+(?:\.\d+)?)\s*(?:minutes?|mins?)', re.IGNORECASE),
        }
        
        # Recurring patterns
        self.recurring_patterns = {
            'daily': re.compile(r'\bdaily\b|\bevery\s+day\b', re.IGNORECASE),
            'weekly': re.compile(r'\bweekly\b|\bevery\s+week\b', re.IGNORECASE),
            'monthly': re.compile(r'\bmonthly\b|\bevery\s+month\b', re.IGNORECASE),
            'yearly': re.compile(r'\byearly\b|\bevery\s+year\b', re.IGNORECASE),
            'weekday': re.compile(r'\bevery\s+(?:monday|tuesday|wednesday|thursday|friday)', re.IGNORECASE),
            'weekend': re.compile(r'\bevery\s+(?:saturday|sunday|weekend)', re.IGNORECASE),
        }
        
        # Fuzzy time patterns
        self.fuzzy_patterns = {
            'soon': re.compile(r'\bsoon\b|\bin\s+the\s+near\s+future\b', re.IGNORECASE),
            'recently': re.compile(r'\brecently\b|\blately\b', re.IGNORECASE),
            'a_while': re.compile(r'\ba\s+while\s+(?:ago|back)\b', re.IGNORECASE),
            'long_ago': re.compile(r'\blong\s+ago\b|\ba\s+long\s+time\s+ago\b', re.IGNORECASE),
            'upcoming': re.compile(r'\bupcoming\b|\bcoming\s+(?:soon|up)\b', re.IGNORECASE),
        }
        
        # Day names
        self.day_names = {
            'monday': 0, 'tuesday': 1, 'wednesday': 2, 'thursday': 3,
            'friday': 4, 'saturday': 5, 'sunday': 6
        }
        
        # Month names
        self.month_names = {
            'january': 1, 'february': 2, 'march': 3, 'april': 4,
            'may': 5, 'june': 6, 'july': 7, 'august': 8,
            'september': 9, 'october': 10, 'november': 11, 'december': 12
        }
        
    def parse(self, text: str) -> Optional[ParsedTime]:
        """
        Parse a temporal expression from natural language text.
        
        Args:
            text: Natural language text containing temporal expression
            
        Returns:
            ParsedTime object or None if no temporal expression found
        """
        # Try each type of parser in order of specificity
        parsers = [
            self._parse_absolute,
            self._parse_relative,
            self._parse_duration,
            self._parse_recurring,
            self._parse_range,
            self._parse_fuzzy
        ]
        
        for parser in parsers:
            result = parser(text)
            if result:
                return result
        
        return None
    
    def _parse_absolute(self, text: str) -> Optional[ParsedTime]:
        """Parse absolute date/time expressions."""
        
        # ISO format: YYYY-MM-DD
        iso_match = re.search(r'(\d{4})-(\d{2})-(\d{2})', text)
        if iso_match:
            year, month, day = map(int, iso_match.groups())
            try:
                dt = datetime(year, month, day)
                return ParsedTime(
                    original_text=text,
                    time_type=TemporalType.ABSOLUTE,
                    start_time=dt,
                    confidence=0.95
                )
            except ValueError:
                pass
        
        # Format: Month DD, YYYY (e.g., "January 15, 2026")
        month_day_year = re.search(
            r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2}),?\s+(\d{4})',
            text,
            re.IGNORECASE
        )
        if month_day_year:
            month_str, day_str, year_str = month_day_year.groups()
            month = self.month_names.get(month_str.lower())
            if month:
                try:
                    dt = datetime(int(year_str), month, int(day_str))
                    return ParsedTime(
                        original_text=text,
                        time_type=TemporalType.ABSOLUTE,
                        start_time=dt,
                        confidence=0.9
                    )
                except ValueError:
                    pass
        
        return None
    
    def _parse_relative(self, text: str) -> Optional[ParsedTime]:
        """Parse relative time expressions."""
        
        # Today
        if self.relative_patterns['today'].search(text):
            today = self.reference_time.replace(hour=0, minute=0, second=0, microsecond=0)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=today,
                end_time=today + timedelta(days=1),
                confidence=0.95
            )
        
        # Tomorrow
        if self.relative_patterns['tomorrow'].search(text):
            tomorrow = (self.reference_time + timedelta(days=1)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=tomorrow,
                end_time=tomorrow + timedelta(days=1),
                confidence=0.95
            )
        
        # Yesterday
        if self.relative_patterns['yesterday'].search(text):
            yesterday = (self.reference_time - timedelta(days=1)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=yesterday,
                end_time=yesterday + timedelta(days=1),
                confidence=0.95
            )
        
        # Next week
        if self.relative_patterns['next_week'].search(text):
            next_week = self.reference_time + timedelta(weeks=1)
            start = next_week.replace(hour=0, minute=0, second=0, microsecond=0)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=start,
                end_time=start + timedelta(weeks=1),
                confidence=0.85
            )
        
        # Next month
        next_month_match = re.search(r'\bnext\s+month\b', text, re.IGNORECASE)
        if next_month_match:
            # Calculate next month
            current_month = self.reference_time.month
            current_year = self.reference_time.year
            
            if current_month == 12:
                next_month_year = current_year + 1
                next_month_num = 1
            else:
                next_month_year = current_year
                next_month_num = current_month + 1
            
            next_month_start = datetime(next_month_year, next_month_num, 1)
            # Calculate end of next month
            if next_month_num == 12:
                next_month_end = datetime(next_month_year + 1, 1, 1)
            else:
                next_month_end = datetime(next_month_year, next_month_num + 1, 1)
            
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=next_month_start,
                end_time=next_month_end,
                confidence=0.85
            )
        
        # Last week
        if self.relative_patterns['last_week'].search(text):
            last_week = self.reference_time - timedelta(weeks=1)
            start = last_week.replace(hour=0, minute=0, second=0, microsecond=0)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=start,
                end_time=start + timedelta(weeks=1),
                confidence=0.85
            )
        
        # X days ago
        match = self.relative_patterns['days_ago'].search(text)
        if match:
            days = int(match.group(1))
            target_date = (self.reference_time - timedelta(days=days)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=target_date,
                end_time=target_date + timedelta(days=1),
                confidence=0.9
            )
        
        # In X days
        match = self.relative_patterns['in_days'].search(text)
        if match:
            days = int(match.group(1))
            target_date = (self.reference_time + timedelta(days=days)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RELATIVE,
                start_time=target_date,
                end_time=target_date + timedelta(days=1),
                confidence=0.9
            )
        
        return None
    
    def _parse_duration(self, text: str) -> Optional[ParsedTime]:
        """Parse duration expressions."""
        
        total_seconds = 0
        
        # Check for hours
        match = self.duration_patterns['hours'].search(text)
        if match:
            total_seconds += float(match.group(1)) * 3600
        
        # Check for minutes
        match = self.duration_patterns['minutes'].search(text)
        if match:
            total_seconds += float(match.group(1)) * 60
        
        # Check for days
        match = self.duration_patterns['days'].search(text)
        if match:
            total_seconds += float(match.group(1)) * 86400
        
        # Check for weeks
        match = self.duration_patterns['weeks'].search(text)
        if match:
            total_seconds += float(match.group(1)) * 604800
        
        # Check for months (approximate)
        match = self.duration_patterns['months'].search(text)
        if match:
            total_seconds += float(match.group(1)) * 2592000  # 30 days
        
        # Check for years (approximate)
        match = self.duration_patterns['years'].search(text)
        if match:
            total_seconds += float(match.group(1)) * 31536000  # 365 days
        
        if total_seconds > 0:
            duration = timedelta(seconds=total_seconds)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.DURATION,
                duration=duration,
                confidence=0.85
            )
        
        return None
    
    def _parse_recurring(self, text: str) -> Optional[ParsedTime]:
        """Parse recurring/repeating patterns."""
        
        # Daily
        if self.recurring_patterns['daily'].search(text):
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RECURRING,
                recurrence_pattern="daily",
                confidence=0.9
            )
        
        # Weekly
        if self.recurring_patterns['weekly'].search(text):
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RECURRING,
                recurrence_pattern="weekly",
                confidence=0.9
            )
        
        # Monthly
        if self.recurring_patterns['monthly'].search(text):
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RECURRING,
                recurrence_pattern="monthly",
                confidence=0.9
            )
        
        # Yearly
        if self.recurring_patterns['yearly'].search(text):
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RECURRING,
                recurrence_pattern="yearly",
                confidence=0.9
            )
        
        # Every [weekday] - enhanced pattern
        weekday_pattern = re.compile(r'\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', re.IGNORECASE)
        weekday_match = weekday_pattern.search(text)
        if weekday_match:
            day_name = weekday_match.group(1).lower()
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.RECURRING,
                recurrence_pattern=f"every_{day_name}",
                confidence=0.9
            )
        
        return None
    
    def _parse_range(self, text: str) -> Optional[ParsedTime]:
        """Parse time range expressions (e.g., "from Monday to Friday")."""
        
        # Simple range pattern: "from X to Y"
        range_match = re.search(r'from\s+(.+?)\s+to\s+(.+)', text, re.IGNORECASE)
        if range_match:
            start_text = range_match.group(1).strip()
            end_text = range_match.group(2).strip()
            
            # Try to parse both endpoints
            start_result = self.parse(start_text)
            end_result = self.parse(end_text)
            
            if start_result and end_result:
                return ParsedTime(
                    original_text=text,
                    time_type=TemporalType.RANGE,
                    start_time=start_result.start_time,
                    end_time=end_result.start_time or end_result.end_time,
                    confidence=0.8
                )
        
        # Enhanced: Handle weekday ranges like "Monday to Friday"
        weekday_range_pattern = re.compile(
            r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+to\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            re.IGNORECASE
        )
        weekday_match = weekday_range_pattern.search(text)
        if weekday_match:
            start_day = weekday_match.group(1).lower()
            end_day = weekday_match.group(2).lower()
            
            # Calculate next occurrence of start day
            start_day_num = self.day_names.get(start_day)
            end_day_num = self.day_names.get(end_day)
            
            if start_day_num is not None and end_day_num is not None:
                # Find next start day
                days_ahead_start = start_day_num - self.reference_time.weekday()
                if days_ahead_start <= 0:  # Target day already happened this week
                    days_ahead_start += 7
                
                start_date = (self.reference_time + timedelta(days=days_ahead_start)).replace(
                    hour=0, minute=0, second=0, microsecond=0
                )
                
                # Calculate end day (same week or next week)
                if end_day_num >= start_day_num:
                    days_ahead_end = days_ahead_start + (end_day_num - start_day_num)
                else:
                    days_ahead_end = days_ahead_start + (7 - start_day_num + end_day_num)
                
                end_date = (self.reference_time + timedelta(days=days_ahead_end)).replace(
                    hour=23, minute=59, second=59, microsecond=0
                )
                
                return ParsedTime(
                    original_text=text,
                    time_type=TemporalType.RANGE,
                    start_time=start_date,
                    end_time=end_date,
                    confidence=0.85
                )
        
        return None
    
    def _parse_fuzzy(self, text: str) -> Optional[ParsedTime]:
        """Parse fuzzy/imprecise time expressions."""
        
        # Soon
        if self.fuzzy_patterns['soon'].search(text):
            soon = self.reference_time + timedelta(days=7)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.FUZZY,
                start_time=self.reference_time,
                end_time=soon,
                confidence=0.5
            )
        
        # Recently
        if self.fuzzy_patterns['recently'].search(text):
            recently = self.reference_time - timedelta(days=7)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.FUZZY,
                start_time=recently,
                end_time=self.reference_time,
                confidence=0.5
            )
        
        # A while ago
        if self.fuzzy_patterns['a_while'].search(text):
            while_ago = self.reference_time - timedelta(days=30)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.FUZZY,
                start_time=while_ago,
                end_time=self.reference_time,
                confidence=0.4
            )
        
        # Long ago
        if self.fuzzy_patterns['long_ago'].search(text):
            long_ago = self.reference_time - timedelta(days=365)
            return ParsedTime(
                original_text=text,
                time_type=TemporalType.FUZZY,
                start_time=long_ago,
                end_time=self.reference_time,
                confidence=0.3
            )
        
        return None
    
    def extract_all_temporal(self, text: str) -> List[ParsedTime]:
        """
        Extract all temporal expressions from text.
        
        Args:
            text: Text to search for temporal expressions
            
        Returns:
            List of all found ParsedTime objects
        """
        results = []
        
        # Split by common delimiters to find multiple expressions
        segments = re.split(r'[,.]', text)
        
        for segment in segments:
            segment = segment.strip()
            if segment:
                parsed = self.parse(segment)
                if parsed:
                    results.append(parsed)
        
        return results


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("TEMPORAL EXPRESSION PARSER - TEST")
    print("="*70)
    
    parser = TemporalExpressionParser()
    
    test_cases = [
        "Schedule meeting for tomorrow",
        "Review data from 3 days ago",
        "Project deadline is January 15, 2026",
        "Run analysis every Monday",
        "Training session for 2 hours",
        "Check predictions from last week",
        "Launch campaign next month",
        "Event scheduled for 2026-03-20",
        "Reminder in 5 days",
        "Report due soon",
        "Analyze trends from recently",
        "Meeting from Monday to Friday",
    ]
    
    print(f"\n📅 Testing {len(test_cases)} temporal expressions:\n")
    
    for i, test_text in enumerate(test_cases, 1):
        result = parser.parse(test_text)
        
        if result:
            print(f"{i}. Input: \"{test_text}\"")
            print(f"   Type: {result.time_type.value}")
            print(f"   Confidence: {result.confidence:.0%}")
            
            if result.start_time:
                print(f"   Start: {result.start_time.strftime('%Y-%m-%d %H:%M')}")
            if result.end_time:
                print(f"   End: {result.end_time.strftime('%Y-%m-%d %H:%M')}")
            if result.duration:
                hours = result.duration.total_seconds() / 3600
                print(f"   Duration: {hours:.1f} hours")
            if result.recurrence_pattern:
                print(f"   Pattern: {result.recurrence_pattern}")
            print()
        else:
            print(f"{i}. ❌ Failed to parse: \"{test_text}\"\n")
    
    print("="*70)
    print("✅ TEMPORAL EXPRESSION PARSER TEST COMPLETE")
    print("="*70)
