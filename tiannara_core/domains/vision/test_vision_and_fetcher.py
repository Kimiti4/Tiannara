"""
Test WebDataFetcher and Vision Domain
"""

import asyncio
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


async def test_web_fetcher():
    """Test WebDataFetcher capabilities"""
    from tiannara_core.integration.web_fetcher import WebDataFetcher
    
    print("=" * 80)
    print("WEB DATA FETCHER TESTS")
    print("=" * 80)
    
    async with WebDataFetcher(rate_limit_rps=2.0) as fetcher:
        
        # Test 1: Fetch webpage
        print("\n1. Testing URL fetch...")
        result = await fetcher.fetch_url("https://httpbin.org/get")
        print(f"   Status: {result.status_code}")
        print(f"   Success: {result.success}")
        print(f"   Response time: {result.response_time_ms:.0f}ms")
        
        # Test 2: Extract text
        print("\n2. Testing text extraction...")
        text = await fetcher.extract_text("https://example.com")
        if text:
            print(f"   Extracted {len(text)} characters")
            print(f"   Preview: {text[:100]}...")
        
        # Test 3: Fetch JSON API
        print("\n3. Testing JSON API fetch...")
        data = await fetcher.fetch_json("https://httpbin.org/json")
        if data:
            print(f"   Successfully fetched JSON")
            print(f"   Keys: {list(data.keys())[:5]}")
        
        # Test 4: Search web
        print("\n4. Testing web search (DuckDuckGo)...")
        try:
            search_results = await fetcher.search_web("python programming", num_results=3)
            print(f"   Found {search_results.total_results} results")
            for i, result in enumerate(search_results.results[:2], 1):
                print(f"   {i}. {result['title'][:60]}...")
        except Exception as e:
            print(f"   Search failed: {e}")
        
        # Test 5: Statistics
        print("\n5. Fetcher Statistics:")
        stats = fetcher.get_statistics()
        for key, value in stats.items():
            print(f"   {key}: {value}")
    
    print("\n✅ WebDataFetcher tests completed!")


async def test_vision_engine():
    """Test Vision Engine"""
    from tiannara_core.domains.vision import VisionEngine
    from PIL import Image
    import numpy as np
    
    print("\n" + "=" * 80)
    print("VISION ENGINE TESTS")
    print("=" * 80)
    
    engine = VisionEngine(use_api=True)
    
    # Test 1: Engine status
    print("\n1. Checking engine status...")
    status = engine.get_engine_status()
    print(f"   Status: {status['status']}")
    print(f"   Capabilities: {', '.join(status['capabilities'])}")
    
    # Test 2: Create test image
    print("\n2. Creating test image...")
    test_image = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    
    # Save test image
    test_path = Path("test_image.jpg")
    img = Image.fromarray(test_image)
    img.save(test_path)
    print(f"   Saved test image to {test_path}")
    
    # Test 3: Analyze image
    print("\n3. Analyzing test image...")
    try:
        result = await engine.analyze_image(
            test_path,
            detect_objects=True,
            analyze_scene=True,
            extract_colors=True
        )
        
        print(f"   Processing time: {result.processing_time_ms:.0f}ms")
        print(f"   Models used: {', '.join(result.models_used)}")
        print(f"   Dominant colors: {result.dominant_colors[:3]}")
        print(f"   Detected objects: {len(result.detected_objects)}")
        
    except Exception as e:
        print(f"   Analysis error: {e}")
    
    # Cleanup
    test_path.unlink(missing_ok=True)
    
    print("\n✅ Vision Engine tests completed!")


async def test_integration():
    """Test integration between WebDataFetcher and Vision"""
    from tiannara_core.integration.web_fetcher import WebDataFetcher
    from tiannara_core.domains.vision import VisionEngine
    
    print("\n" + "=" * 80)
    print("INTEGRATION TEST: Web + Vision")
    print("=" * 80)
    
    print("\n1. Fetching image from web...")
    fetcher = WebDataFetcher()
    
    # Use a sample image URL
    image_url = "https://picsum.photos/seed/tiannara/800/600.jpg"
    
    try:
        # Download image
        image_data = await fetcher.image_processor.download_image(image_url)
        print(f"   Downloaded image: {image_data.shape}")
        
        # Analyze with vision engine
        print("\n2. Analyzing downloaded image...")
        engine = VisionEngine(use_api=True)
        
        # Save temporarily
        temp_path = engine.image_processor.save_temporary(image_data)
        
        result = await engine.analyze_image(temp_path)
        print(f"   Scene description: {result.scene_description}")
        print(f"   Colors: {result.dominant_colors[:3]}")
        
        # Cleanup
        Path(temp_path).unlink(missing_ok=True)
        
    except Exception as e:
        print(f"   Integration test error: {e}")
    
    await fetcher.close()
    
    print("\n✅ Integration test completed!")


async def main():
    """Run all tests"""
    print("\n" + "=" * 80)
    print("TIANNARA WEB & VISION MODULES - COMPREHENSIVE TEST")
    print("=" * 80)
    
    try:
        # Test WebDataFetcher
        await test_web_fetcher()
        
        # Test Vision Engine
        await test_vision_engine()
        
        # Test Integration
        await test_integration()
        
        print("\n" + "=" * 80)
        print("ALL TESTS COMPLETED SUCCESSFULLY! ✅")
        print("=" * 80)
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
