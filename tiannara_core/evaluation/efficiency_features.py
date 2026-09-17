"""
Efficiency Features: Email Assistant, Report Generator, and Code Helper.

Automates common tasks to boost productivity.
"""

from typing import Dict, List, Optional
from datetime import datetime


class EmailAssistant:
    """
    AI-powered email writing assistant.
    
    Generates professional emails based on intent and context.
    """
    
    def __init__(self):
        self.templates = self._load_templates()
    
    def _load_templates(self) -> Dict:
        """Load email templates for different scenarios"""
        return {
            "follow_up": {
                "subject": "Following up on {topic}",
                "body": """Hi {recipient},

I hope this email finds you well. I'm following up on {topic} that we discussed {timeframe}.

{context}

Would you have time for a quick call this week to discuss further?

Best regards,
{sender}"""
            },
            "meeting_request": {
                "subject": "Meeting Request: {topic}",
                "body": """Hi {recipient},

I'd like to schedule a meeting to discuss {topic}.

Purpose: {purpose}
Proposed duration: {duration}
Suggested times: {times}

Please let me know what works for your schedule.

Best,
{sender}"""
            },
            "status_update": {
                "subject": "Status Update: {project}",
                "body": """Hi {recipient},

Here's a quick update on {project}:

Progress:
{progress_items}

Next Steps:
{next_steps}

Blockers:
{blockers}

Let me know if you have any questions.

Thanks,
{sender}"""
            },
            "customer_response": {
                "subject": "Re: {customer_inquiry}",
                "body": """Dear {customer_name},

Thank you for reaching out regarding {inquiry}.

{response}

If you have any additional questions, please don't hesitate to ask.

Best regards,
{sender}
{title}"""
            }
        }
    
    def generate_email(self, purpose: str, tone: str = "professional",
                      recipients: List[str] = None, context: Dict = None) -> Dict:
        """
        Generate a professional email based on intent.
        
        Args:
            purpose: Type of email (follow_up, meeting_request, status_update, customer_response)
            tone: Email tone (professional, casual, formal, friendly)
            recipients: List of recipient names
            context: Additional context for personalization
            
        Returns:
            Dictionary with subject and body
        """
        if purpose not in self.templates:
            raise ValueError(f"Unknown email purpose: {purpose}")
        
        template = self.templates[purpose]
        context = context or {}
        
        # Fill in template variables
        subject = template["subject"].format(**context)
        body = template["body"].format(**context)
        
        # Adjust tone if needed
        if tone == "casual":
            body = self._make_casual(body)
        elif tone == "formal":
            body = self._make_formal(body)
        elif tone == "friendly":
            body = self._make_friendly(body)
        
        return {
            "subject": subject,
            "body": body,
            "recipients": recipients or [],
            "generated_at": datetime.now().isoformat(),
            "tone": tone,
            "purpose": purpose
        }
    
    def _make_casual(self, text: str) -> str:
        """Convert email to casual tone"""
        replacements = {
            "Best regards": "Cheers",
            "Dear": "Hi",
            "I hope this email finds you well": "Hope you're doing well",
            "Please let me know": "Let me know",
            "Sincerely": "Best"
        }
        
        for old, new in replacements.items():
            text = text.replace(old, new)
        
        return text
    
    def _make_formal(self, text: str) -> str:
        """Convert email to formal tone"""
        replacements = {
            "Hi": "Dear",
            "Cheers": "Sincerely",
            "Best": "Respectfully",
            "Thanks": "Thank you",
            "Let me know": "Please advise"
        }
        
        for old, new in replacements.items():
            text = text.replace(old, new)
        
        return text
    
    def _make_friendly(self, text: str) -> str:
        """Convert email to friendly tone"""
        replacements = {
            "Best regards": "Best wishes",
            "Dear": "Hello",
            "I hope this email finds you well": "Hope you're having a great day!",
            "Please let me know": "Feel free to reach out",
            "Sincerely": "Warm regards"
        }
        
        for old, new in replacements.items():
            text = text.replace(old, new)
        
        return text


class ReportGenerator:
    """
    Automated report generation from data.
    
    Creates various report types with proper structure and formatting.
    """
    
    def __init__(self):
        self.report_templates = self._load_templates()
    
    def _load_templates(self) -> Dict:
        """Load report templates"""
        return {
            "performance_analysis": {
                "sections": [
                    "executive_summary",
                    "key_metrics",
                    "trend_analysis",
                    "recommendations"
                ]
            },
            "experiment_results": {
                "sections": [
                    "objective",
                    "methodology",
                    "results",
                    "analysis",
                    "conclusions"
                ]
            },
            "business_intelligence": {
                "sections": [
                    "market_overview",
                    "competitive_analysis",
                    "opportunities",
                    "risks",
                    "strategic_recommendations"
                ]
            },
            "technical_documentation": {
                "sections": [
                    "overview",
                    "architecture",
                    "implementation_details",
                    "api_reference",
                    "examples"
                ]
            }
        }
    
    def generate_report(self, data: Dict, report_type: str, 
                       format: str = "markdown") -> str:
        """
        Generate a structured report from data.
        
        Args:
            data: Report data including metrics, findings, etc.
            report_type: Type of report (performance_analysis, experiment_results, etc.)
            format: Output format (markdown, html, plain_text)
            
        Returns:
            Formatted report string
        """
        if report_type not in self.report_templates:
            raise ValueError(f"Unknown report type: {report_type}")
        
        template = self.report_templates[report_type]
        
        # Generate report sections
        sections = []
        for section in template["sections"]:
            section_content = self._generate_section(section, data, report_type)
            sections.append(section_content)
        
        # Combine into full report
        report = self._assemble_report(sections, report_type, format)
        
        return report
    
    def _generate_section(self, section: str, data: Dict, 
                         report_type: str) -> str:
        """Generate content for a specific section"""
        
        if section == "executive_summary":
            return self._executive_summary(data)
        elif section == "key_metrics":
            return self._key_metrics(data)
        elif section == "trend_analysis":
            return self._trend_analysis(data)
        elif section == "recommendations":
            return self._recommendations(data)
        elif section == "objective":
            return f"## Objective\n\n{data.get('objective', 'Not specified')}"
        elif section == "methodology":
            return f"## Methodology\n\n{data.get('methodology', 'Not specified')}"
        elif section == "results":
            return self._format_results(data.get('results', {}))
        elif section == "analysis":
            return f"## Analysis\n\n{data.get('analysis', 'Analysis pending')}"
        elif section == "conclusions":
            return f"## Conclusions\n\n{data.get('conclusions', 'Conclusions pending')}"
        else:
            return f"## {section.replace('_', ' ').title()}\n\nContent pending"
    
    def _executive_summary(self, data: Dict) -> str:
        """Generate executive summary"""
        summary = "## Executive Summary\n\n"
        summary += f"**Report Date**: {datetime.now().strftime('%Y-%m-%d')}\n\n"
        summary += f"**Key Findings**:\n\n"
        
        findings = data.get("findings", [])
        for i, finding in enumerate(findings[:5], 1):
            summary += f"{i}. {finding}\n"
        
        summary += f"\n**Overall Assessment**: {data.get('assessment', 'See detailed analysis')}\n"
        
        return summary
    
    def _key_metrics(self, data: Dict) -> str:
        """Format key metrics"""
        section = "## Key Metrics\n\n"
        
        metrics = data.get("metrics", {})
        for metric_name, value in metrics.items():
            section += f"- **{metric_name.replace('_', ' ').title()}**: {value}\n"
        
        return section
    
    def _trend_analysis(self, data: Dict) -> str:
        """Analyze trends"""
        section = "## Trend Analysis\n\n"
        
        trends = data.get("trends", [])
        for trend in trends:
            section += f"- {trend}\n"
        
        return section
    
    def _recommendations(self, data: Dict) -> str:
        """Generate recommendations"""
        section = "## Recommendations\n\n"
        
        recommendations = data.get("recommendations", [])
        for i, rec in enumerate(recommendations, 1):
            section += f"{i}. **{rec['action']}**: {rec['rationale']}\n"
        
        return section
    
    def _format_results(self, results: Dict) -> str:
        """Format experimental results"""
        section = "## Results\n\n"
        
        for test_name, result in results.items():
            section += f"### {test_name}\n\n"
            section += f"- **Success Rate**: {result.get('success_rate', 'N/A')}\n"
            section += f"- **Accuracy**: {result.get('accuracy', 'N/A')}\n"
            section += f"- **Samples**: {result.get('samples', 'N/A')}\n\n"
        
        return section
    
    def _assemble_report(self, sections: List[str], report_type: str, 
                        format: str) -> str:
        """Assemble sections into complete report"""
        
        if format == "markdown":
            title = report_type.replace('_', ' ').title()
            report = f"# {title} Report\n\n"
            report += f"*Generated on {datetime.now().strftime('%Y-%m-%d at %H:%M')}*\n\n"
            report += "---\n\n"
            report += "\n\n".join(sections)
            
        elif format == "html":
            title = report_type.replace('_', ' ').title()
            report = f"<h1>{title} Report</h1>\n"
            report += f"<p><em>Generated on {datetime.now().strftime('%Y-%m-%d at %H:%M')}</em></p>\n"
            report += "<hr>\n"
            report += "\n".join(sections)  # Would need HTML conversion
            
        else:  # plain_text
            title = report_type.replace('_', ' ').title()
            report = f"{title.upper()} REPORT\n"
            report += "=" * 80 + "\n"
            report += f"Generated on {datetime.now().strftime('%Y-%m-%d at %H:%M')}\n"
            report += "=" * 80 + "\n\n"
            report += "\n\n".join([s.replace('#', '').replace('*', '') for s in sections])
        
        return report


class CodeAssistant:
    """
    Intelligent code debugging and optimization assistant.
    """
    
    def __init__(self):
        self.common_errors = self._load_error_patterns()
    
    def _load_error_patterns(self) -> Dict:
        """Load common error patterns and fixes"""
        return {
            "SyntaxError": {
                "description": "Syntax error in code",
                "common_causes": [
                    "Missing colon after function/class definition",
                    "Mismatched parentheses or brackets",
                    "Incorrect indentation",
                    "Missing quotes around strings"
                ],
                "fix_strategy": "Check syntax carefully, use linter"
            },
            "TypeError": {
                "description": "Operation on incompatible types",
                "common_causes": [
                    "Adding string to number",
                    "Calling non-callable object",
                    "Wrong number of arguments"
                ],
                "fix_strategy": "Check variable types, add type hints"
            },
            "NameError": {
                "description": "Undefined variable or function",
                "common_causes": [
                    "Typo in variable name",
                    "Variable not initialized",
                    "Missing import"
                ],
                "fix_strategy": "Check spelling, ensure imports are present"
            },
            "IndexError": {
                "description": "List index out of range",
                "common_causes": [
                    "Accessing beyond list length",
                    "Empty list access",
                    "Off-by-one error"
                ],
                "fix_strategy": "Check list length before accessing"
            },
            "KeyError": {
                "description": "Dictionary key not found",
                "common_causes": [
                    "Typo in key name",
                    "Key doesn't exist",
                    "Case sensitivity issue"
                ],
                "fix_strategy": "Use .get() method or check key existence"
            }
        }
    
    def debug_code(self, code: str, error_message: str, 
                  context: Dict = None) -> Dict:
        """
        Analyze code errors and provide fixes.
        
        Args:
            code: The problematic code
            error_message: Error message from interpreter
            context: Additional context (variable values, etc.)
            
        Returns:
            Analysis with issue explanation and fix suggestion
        """
        # Identify error type
        error_type = self._identify_error_type(error_message)
        
        if error_type in self.common_errors:
            pattern = self.common_errors[error_type]
            
            return {
                "issue": pattern["description"],
                "error_type": error_type,
                "explanation": self._explain_error(error_type, error_message),
                "possible_causes": pattern["common_causes"],
                "fix": pattern["fix_strategy"],
                "confidence": 0.85,
                "code_suggestion": self._suggest_fix(code, error_type)
            }
        else:
            return {
                "issue": "Unknown error",
                "error_type": error_type,
                "explanation": error_message,
                "possible_causes": ["Review error message carefully"],
                "fix": "Consult documentation or search for error message",
                "confidence": 0.5,
                "code_suggestion": None
            }
    
    def _identify_error_type(self, error_message: str) -> str:
        """Identify the type of error from message"""
        error_types = [
            "SyntaxError", "TypeError", "NameError", 
            "IndexError", "KeyError", "ValueError",
            "AttributeError", "ImportError", "FileNotFoundError"
        ]
        
        for error_type in error_types:
            if error_type in error_message:
                return error_type
        
        return "UnknownError"
    
    def _explain_error(self, error_type: str, error_message: str) -> str:
        """Provide human-readable explanation of error"""
        explanations = {
            "SyntaxError": "The code has a syntax problem that prevents Python from understanding it.",
            "TypeError": "You're trying to perform an operation on incompatible data types.",
            "NameError": "You're using a variable or function that hasn't been defined yet.",
            "IndexError": "You're trying to access a list position that doesn't exist.",
            "KeyError": "You're trying to access a dictionary key that isn't there."
        }
        
        return explanations.get(error_type, f"Error: {error_message}")
    
    def _suggest_fix(self, code: str, error_type: str) -> Optional[str]:
        """Suggest code fix based on error type"""
        
        if error_type == "SyntaxError":
            return "# Check for missing colons, parentheses, or indentation issues"
        elif error_type == "TypeError":
            return "# Add type checking: if isinstance(variable, expected_type)"
        elif error_type == "NameError":
            return "# Ensure all variables are defined before use"
        elif error_type == "IndexError":
            return "# Check length: if index < len(my_list)"
        elif error_type == "KeyError":
            return "# Use safe access: my_dict.get('key', default_value)"
        
        return None
    
    def improve_code(self, code: str, goal: str = "performance") -> str:
        """
        Suggest improvements to code.
        
        Args:
            code: Original code
            goal: Improvement goal (performance, readability, maintainability, security)
            
        Returns:
            Improved code with comments explaining changes
        """
        improvements = []
        
        if goal == "performance":
            improvements = self._optimize_performance(code)
        elif goal == "readability":
            improvements = self._improve_readability(code)
        elif goal == "maintainability":
            improvements = self._improve_maintainability(code)
        elif goal == "security":
            improvements = self._improve_security(code)
        
        # Apply improvements
        improved_code = code
        for improvement in improvements:
            improved_code = improvement["apply"](improved_code)
        
        # Add comment header
        header = f"# Improved for: {goal}\n"
        header += "# Changes:\n"
        for imp in improvements:
            header += f"# - {imp['description']}\n"
        header += "\n"
        
        return header + improved_code
    
    def _optimize_performance(self, code: str) -> List[Dict]:
        """Suggest performance optimizations"""
        suggestions = []
        
        # Check for common performance issues
        if "for i in range(len(" in code:
            suggestions.append({
                "description": "Use enumerate() instead of range(len())",
                "apply": lambda c: c.replace("for i in range(len(", "for i, item in enumerate(")
            })
        
        if ".append(" in code and "list" in code.lower():
            suggestions.append({
                "description": "Consider list comprehension for better performance",
                "apply": lambda c: c  # Would need AST parsing for real implementation
            })
        
        return suggestions
    
    def _improve_readability(self, code: str) -> List[Dict]:
        """Suggest readability improvements"""
        suggestions = []
        
        # Check for long lines
        lines = code.split('\n')
        long_lines = [i for i, line in enumerate(lines) if len(line) > 100]
        if long_lines:
            suggestions.append({
                "description": f"Break long lines (found {len(long_lines)} lines >100 chars)",
                "apply": lambda c: c  # Would need formatting logic
            })
        
        # Check for missing docstrings
        if "def " in code and '"""' not in code:
            suggestions.append({
                "description": "Add docstrings to functions",
                "apply": lambda c: c  # Would need to insert docstrings
            })
        
        return suggestions
    
    def _improve_maintainability(self, code: str) -> List[Dict]:
        """Suggest maintainability improvements"""
        suggestions = []
        
        # Check for magic numbers
        import re
        magic_numbers = re.findall(r'(?<!\w)\d{2,}(?!\w)', code)
        if magic_numbers:
            suggestions.append({
                "description": f"Replace magic numbers with named constants ({len(set(magic_numbers))} found)",
                "apply": lambda c: c  # Would extract constants
            })
        
        return suggestions
    
    def _improve_security(self, code: str) -> List[Dict]:
        """Suggest security improvements"""
        suggestions = []
        
        # Check for SQL injection risks
        if "execute(" in code and "+" in code:
            suggestions.append({
                "description": "Use parameterized queries to prevent SQL injection",
                "apply": lambda c: c  # Would fix SQL queries
            })
        
        # Check for hardcoded credentials
        if "password" in code.lower() and "=" in code:
            suggestions.append({
                "description": "Move credentials to environment variables",
                "apply": lambda c: c  # Would externalize credentials
            })
        
        return suggestions


# Singleton instances
email_assistant = EmailAssistant()
report_generator = ReportGenerator()
code_assistant = CodeAssistant()
