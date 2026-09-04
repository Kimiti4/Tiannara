"""Comprehensive fix for all Unicode issues in demonstration_projects.py"""

with open('tiannara_core/evaluation/demonstration_projects.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace all problematic Unicode characters
replacements = {
    '→': '->',
    '×': 'x',
    '•': '-',
    '€': 'EUR ',
    '□': 'x'
}

for unicode_char, ascii_char in replacements.items():
    content = content.replace(unicode_char, ascii_char)

with open('tiannara_core/evaluation/demonstration_projects.py', 'w', encoding='utf-8') as f:
    f.write(content)

print("All Unicode characters replaced!")
