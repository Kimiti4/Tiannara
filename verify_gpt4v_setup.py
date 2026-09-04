"""
Quick verification that GPT-4V integration is working with .env file
"""

from dotenv import load_dotenv
load_dotenv('.env')

import os
from tiannara_core.domains.vision import GPT4VAnalyzer

print("="*60)
print("GPT-4V INTEGRATION VERIFICATION")
print("="*60)

# Check environment variable
api_key = os.getenv('OPENAI_API_KEY')
if api_key:
    print(f"✓ OPENAI_API_KEY found in .env file")
    print(f"  Format: {api_key[:15]}...{api_key[-4:]}")
    print(f"  Valid: {api_key.startswith('sk-')}")
else:
    print("✗ OPENAI_API_KEY not found")
    exit(1)

# Initialize analyzer (auto-loads from env)
print("\nInitializing GPT-4V Analyzer...")
analyzer = GPT4VAnalyzer()

if analyzer.available:
    print("✅ SUCCESS! GPT-4V integration is ready.")
    print("\nYou can now use:")
    print("  - Image descriptions")
    print("  - Visual question answering")
    print("  - Alt-text generation")
    print("  - Quality assessment")
    print("  - Content moderation")
else:
    print("❌ FAILED to initialize GPT-4V")
    print("Check your API key and OpenAI account status")
