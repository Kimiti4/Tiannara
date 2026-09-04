#!/usr/bin/env python3
"""
Automated script to register Phase 4 Observatory router in Tiannara API main.py

This script adds the necessary import and router registration lines.
Run from the project root directory.
"""

import os
import sys
from pathlib import Path

def register_observatory_router():
    """Add observatory router to tiannara_api/main.py"""
    
    main_py_path = Path("tiannara_api/main.py")
    
    if not main_py_path.exists():
        print(f"❌ Error: {main_py_path} not found")
        print("   Make sure you're running this from the project root directory")
        sys.exit(1)
    
    print(f"📝 Reading {main_py_path}...")
    
    with open(main_py_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if already registered
    if "from tiannara_api.routes.observatory import" in content:
        print("✅ Observatory import already exists")
    else:
        # Add import after api_keys import
        import_line = "from tiannara_api.routes.api_keys import router as api_keys_router  # API key management"
        new_import = import_line + "\nfrom tiannara_api.routes.observatory import router as observatory_router  # Phase 4 Observatory backend integration"
        
        content = content.replace(import_line, new_import)
        print("✅ Added observatory router import")
    
    # Check if router already registered
    if "app.include_router(observatory_router" in content:
        print("✅ Observatory router already registered")
    else:
        # Add router registration after api_keys router
        router_line = 'app.include_router(api_keys_router, prefix="/api/v1")  # API key management'
        new_router = router_line + '\napp.include_router(observatory_router, prefix="/api/v1")  # Phase 4 Observatory (real-time cognitive state)'
        
        content = content.replace(router_line, new_router)
        print("✅ Registered observatory router")
    
    # Write back
    with open(main_py_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"\n✅ Successfully updated {main_py_path}")
    print("\nNext steps:")
    print("1. Start Tiannara Runtime: cd tiannara_runtime && mix phx.server")
    print("2. Start Tiannara API: cd tiannara_api && uvicorn main:app --reload --port 8000")
    print("3. Start Dashboard: cd tiannara_internal_dashboard && npm run dev")
    print("4. Test health check: curl http://localhost:8000/api/v1/observatory/health")

if __name__ == "__main__":
    register_observatory_router()
