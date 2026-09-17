"""
Test GPT-4V Integration with Environment Variable

Verifies that the OpenAI API key is properly loaded from .env file.
"""

import asyncio
import os
from pathlib import Path
import sys

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Load environment variables from .env
try:
    from dotenv import load_dotenv
    env_path = project_root / '.env'
    if env_path.exists():
        load_dotenv(env_path)
        print("✓ Loaded .env file")
    else:
        print("⚠ .env file not found")
except ImportError:
    print("⚠ python-dotenv not installed. Install with: pip install python-dotenv")


async def test_gpt4v_initialization():
    """Test GPT-4V analyzer initialization"""
    print("\n" + "="*60)
    print("TESTING GPT-4V INITIALIZATION")
    print("="*60)
    
    # Check if API key is set
    api_key = os.getenv('OPENAI_API_KEY')
    
    if api_key:
        print(f"✓ OPENAI_API_KEY found in environment")
        print(f"  Key format: {api_key[:10]}...{api_key[-4:]}")
        
        if api_key.startswith('sk-'):
            print("✓ API key has correct format (starts with 'sk-')")
        else:
            print("✗ API key has incorrect format (should start with 'sk-')")
            return False
    else:
        print("✗ OPENAI_API_KEY not found in environment")
        print("  Make sure you've added it to your .env file")
        return False
    
    # Try to initialize GPT-4V analyzer
    try:
        from tiannara_core.domains.vision import GPT4VAnalyzer
        
        print("\nInitializing GPT-4V Analyzer...")
        analyzer = GPT4VAnalyzer()  # Should auto-load from env var
        
        if analyzer.available:
            print("✓ GPT-4V Analyzer initialized successfully!")
            print("  Status: Available")
            return True
        else:
            print("✗ GPT-4V Analyzer initialization failed")
            print("  Status: Not available")
            return False
            
    except Exception as e:
        print(f"✗ Error initializing GPT-4V Analyzer: {e}")
        return False


async def test_basic_api_call():
    """Test a basic API call (optional - requires credits)"""
    print("\n" + "="*60)
    print("OPTIONAL: TEST BASIC API CALL")
    print("="*60)
    print("\nThis will make a real API call to OpenAI.")
    print("It will consume API credits (~$0.01).")
    
    response = input("Continue? (yes/no): ").strip().lower()
    
    if response != 'yes':
        print("Skipped API call test")
        return
    
    try:
        from tiannara_core.domains.vision import GPT4VAnalyzer
        
        analyzer = GPT4VAnalyzer()
        
        if not analyzer.available:
            print("✗ GPT-4V not available, skipping API call")
            return
        
        # Create a simple test image (1x1 pixel)
        import numpy as np
        from PIL import Image
        import io
        
        # Create a simple colored image
        img_array = np.zeros((100, 100, 3), dtype=np.uint8)
        img_array[:, :] = [255, 100, 50]  # Orange color
        img = Image.fromarray(img_array)
        
        # Save to bytes
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        
        print("\nMaking test API call...")
        description = await analyzer.describe(buffer.getvalue(), detail_level="low")
        
        print(f"✓ API call successful!")
        print(f"  Description: {description[:100]}...")
        
    except Exception as e:
        print(f"✗ API call failed: {e}")
        import traceback
        traceback.print_exc()


async def main():
    """Run all tests"""
    print("\n" + "="*60)
    print("TIANNARA GPT-4V INTEGRATION TEST")
    print("="*60)
    
    # Test 1: Initialization
    init_success = await test_gpt4v_initialization()
    
    if init_success:
        print("\n✅ GPT-4V integration is ready to use!")
        print("\nUsage example:")
        print("""
from tiannara_core.domains.vision import GPT4VAnalyzer

# Automatically loads API key from .env
analyzer = GPT4VAnalyzer()

# Describe an image
description = await analyzer.describe("photo.jpg")

# Ask questions about images
answer = await analyzer.ask("diagram.png", "What does this show?")
        """)
    else:
        print("\n❌ GPT-4V integration needs configuration")
        print("\nTo fix:")
        print("1. Ensure OPENAI_API_KEY is set in your .env file")
        print("2. Verify the key starts with 'sk-'")
        print("3. Check that you have GPT-4V access on your OpenAI account")
    
    # Test 2: Optional API call
    print("\n")
    await test_basic_api_call()
    
    print("\n" + "="*60)
    print("TEST COMPLETE")
    print("="*60 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
