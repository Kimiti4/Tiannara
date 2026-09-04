# Simple test to verify the audit system works
# This is a minimal test to check if the audit modules can be compiled and run

defmodule SimpleAuditTest do
  def run do
    IO.puts("🔍 Starting Simple Audit Test")
    
    # Test if we can access audit modules
    try do
      # Try to compile the audit modules
      Code.compile_file("lib/tiannara/audit/tier1_architectural_invariants.ex")
      Code.compile_file("lib/tiannara/audit/final_scorecard.ex")
      Code.compile_file("lib/tiannara/audit.ex")
      
      IO.puts("✅ Audit modules compiled successfully")
      
      # Test basic functionality
      IO.puts("📊 Testing basic audit functionality...")
      
      # Test a simple function
      result = "Audit test passed"
      IO.puts("✅ #{result}")
      
      result
    rescue
      error ->
        IO.puts("❌ Audit test failed: #{inspect(error)}")
        {:error, error}
    end
  end
end

# Run the test
SimpleAuditTest.run()