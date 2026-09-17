"""
Model Quantization Test and Example Script

Demonstrates the complete quantization workflow:
1. Create a sample model
2. Export to ONNX
3. Validate ONNX export
4. Quantize to INT8 and FP16
5. Profile memory usage
6. Compare results

Usage:
    python tiannara_core/models/test_quantization.py
"""

import sys
import numpy as np
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.models.onnx_export import export_to_onnx, validate_onnx_model
from tiannara_core.models.quantization import (
    quantize_int8, 
    quantize_fp16, 
    profile_memory_usage,
    prune_model
)


def sample_model(x: np.ndarray, weights: np.ndarray) -> np.ndarray:
    """
    Sample model for testing - simple linear transformation.
    
    This represents a typical reasoning component that would benefit
    from quantization for edge deployment.
    """
    return np.dot(x, weights) + 0.1


def create_test_data() -> dict:
    """Create sample test data for validation."""
    np.random.seed(42)
    
    return {
        'x': np.random.randn(10, 20).astype(np.float32),
        'weights': np.random.randn(20, 5).astype(np.float32)
    }


def main():
    """Run complete quantization pipeline demonstration."""
    
    print("=" * 70)
    print("Tiannara Model Quantization Pipeline - Test & Demo")
    print("=" * 70)
    print()
    
    # Create output directory
    output_dir = project_root / "model_exports"
    output_dir.mkdir(exist_ok=True)
    
    # Step 1: Export to ONNX
    print("📦 Step 1: Exporting model to ONNX...")
    print("-" * 70)
    
    input_signature = {
        'x': ((10, 20), np.float32),
        'weights': ((20, 5), np.float32)
    }
    
    onnx_path = output_dir / "sample_model.onnx"
    
    try:
        export_to_onnx(
            sample_model,
            str(onnx_path),
            input_signature=input_signature,
            sample_inputs=create_test_data()
        )
        print(f"✅ Model exported to: {onnx_path}")
        print()
        
    except Exception as e:
        print(f"⚠️  ONNX export skipped (dependencies may not be installed): {e}")
        print("   Install with: pip install onnx onnxruntime")
        print()
        return
    
    # Step 2: Validate ONNX model
    print("✅ Step 2: Validating ONNX model...")
    print("-" * 70)
    
    test_data = create_test_data()
    
    try:
        validation_result = validate_onnx_model(
            str(onnx_path),
            test_inputs=test_data,
            original_func=sample_model
        )
        
        print(f"Valid: {'✅ Yes' if validation_result.is_valid else '❌ No'}")
        print(f"Accuracy retained: {validation_result.accuracy_retained:.2f}%")
        print(f"Inference time: {validation_result.inference_time_ms:.2f} ms")
        
        if validation_result.warnings:
            print(f"Warnings: {validation_result.warnings}")
        
        if validation_result.errors:
            print(f"Errors: {validation_result.errors}")
        
        print()
        
    except Exception as e:
        print(f"⚠️  Validation failed: {e}")
        print()
    
    # Step 3: Profile memory usage
    print("📊 Step 3: Profiling memory usage...")
    print("-" * 70)
    
    try:
        profile = profile_memory_usage(str(onnx_path))
        
        print(f"Total parameters: {profile.total_parameters:,}")
        print(f"Model size: {profile.model_size_mb:.2f} MB")
        print(f"Weight memory: {profile.weight_memory_mb:.2f} MB")
        print(f"Activation memory: {profile.activation_memory_mb:.2f} MB")
        print(f"Peak memory: {profile.peak_memory_mb:.2f} MB")
        print(f"Edge compatible (<512MB): {'✅ Yes' if profile.estimated_edge_compatible else '❌ No'}")
        print()
        
    except Exception as e:
        print(f"⚠️  Profiling failed: {e}")
        print()
    
    # Step 4: INT8 Quantization
    print("🔢 Step 4: INT8 Quantization...")
    print("-" * 70)
    
    try:
        calibration_data = [create_test_data() for _ in range(5)]
        
        int8_result = quantize_int8(
            str(onnx_path),
            calibration_data=calibration_data
        )
        
        if not int8_result.errors:
            print(f"Original size: {int8_result.original_size_kb:.1f} KB")
            print(f"Quantized size: {int8_result.quantized_size_kb:.1f} KB")
            print(f"Size reduction: {int8_result.size_reduction_pct:.1f}%")
            print(f"Accuracy retained: {int8_result.accuracy_retained_pct:.2f}%")
            print(f"Speedup: {int8_result.inference_speedup_pct:.1f}%")
            print(f"Output: {int8_result.output_path}")
        else:
            print(f"⚠️  INT8 quantization failed: {int8_result.errors}")
        
        print()
        
    except Exception as e:
        print(f"⚠️  INT8 quantization skipped: {e}")
        print()
    
    # Step 5: FP16 Quantization
    print("🔣 Step 5: FP16 Quantization...")
    print("-" * 70)
    
    try:
        fp16_result = quantize_fp16(str(onnx_path))
        
        if not fp16_result.errors:
            print(f"Original size: {fp16_result.original_size_kb:.1f} KB")
            print(f"Quantized size: {fp16_result.quantized_size_kb:.1f} KB")
            print(f"Size reduction: {fp16_result.size_reduction_pct:.1f}%")
            print(f"Accuracy retained: {fp16_result.accuracy_retained_pct:.2f}%")
            print(f"Estimated speedup: {fp16_result.inference_speedup_pct:.1f}%")
            print(f"Output: {fp16_result.output_path}")
        else:
            print(f"⚠️  FP16 quantization failed: {fp16_result.errors}")
        
        print()
        
    except Exception as e:
        print(f"⚠️  FP16 quantization skipped: {e}")
        print()
    
    # Step 6: Model Pruning
    print("✂️  Step 6: Model Pruning...")
    print("-" * 70)
    
    try:
        pruned_path = prune_model(
            str(onnx_path),
            sparsity_target=0.3
        )
        
        original_size = onnx_path.stat().st_size / 1024
        pruned_size = Path(pruned_path).stat().st_size / 1024
        reduction = ((original_size - pruned_size) / original_size) * 100
        
        print(f"Original size: {original_size:.1f} KB")
        print(f"Pruned size: {pruned_size:.1f} KB")
        print(f"Size reduction: {reduction:.1f}%")
        print(f"Output: {pruned_path}")
        print()
        
    except Exception as e:
        print(f"⚠️  Pruning failed: {e}")
        print()
    
    # Summary
    print("=" * 70)
    print("📋 Summary")
    print("=" * 70)
    print()
    print("Quantization pipeline completed!")
    print()
    print("Next steps:")
    print("1. Test quantized models on target edge devices")
    print("2. Validate accuracy on real-world data")
    print("3. Deploy using ONNX Runtime for inference")
    print()
    print("For production deployment:")
    print("- Target <512MB memory footprint for edge devices")
    print("- Maintain >95% accuracy after quantization")
    print("- Use INT8 for maximum size reduction")
    print("- Use FP16 for better accuracy/speed tradeoff")
    print()


if __name__ == "__main__":
    main()
