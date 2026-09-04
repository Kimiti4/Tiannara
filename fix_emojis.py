"""Fix emoji encoding issues in demonstration_projects.py"""

import re

# Read file
with open('tiannara_core/evaluation/demonstration_projects.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace emojis with ASCII
replacements = {
    '📋': '[USE CASE]',
    '⚙️': '[BUILDING]',
    '✓': '[OK]',
    '💡': '[INSIGHT]',
    '🎯': '[IMPACT]',
    '📊': '[METRICS]',
    '📈': '[COMPARISON]',
    '⚡': '[IMPROVEMENT]',
    '✅': '[COMPLETE]',
    '💰': '[ROI]',
    '🏆': '[ADVANTAGE]',
    '📁': '[FILE]',
    '🚀': '[LAUNCH]'
}

for emoji, text in replacements.items():
    content = content.replace(emoji, text)

# Write back
with open('tiannara_core/evaluation/demonstration_projects.py', 'w', encoding='utf-8') as f:
    f.write(content)

print("Emojis replaced successfully!")
