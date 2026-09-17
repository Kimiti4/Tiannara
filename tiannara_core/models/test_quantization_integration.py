"""
Model Quantization Integration Test.

Tests INT8 and FP16 quantization with real Tiannara models.
Demonstrates memory savings and inference speedup for edge deployment.

Usage:
    python tiannara_core/models/test_quantization_integration.py
"""

import sys
from pathlib import Path
import numpy as np
import time

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.models.quantization import (
        quantize_int8,
        quantize_fp16,
        profile_memory_usage,
        prune_model,
        QuantizationResult,
        MemoryProfile
    )
    QUANT_AVAILABLE = True
except ImportError as e:
    print(f"WARNING: Quantization module not fully available: {e}")
    QUANT_AVAILABLE = False


def create_test_onnx_model(output_path="test_model.onnx"):
    """Create a simple ONNX model for testing quantization."""
    
    try:
        import onnx
        from onnx import helper, TensorProto, numpy_helper
        
        # Create a simple 2-layer neural network
        # Input -> Linear(128->64) -> ReLU -> Linear(64->10) -> Output
        
        # Define input
        input_tensor = helper.make_tensor_value_info('input', TensorProto.FLOAT, [None, 128])
        output_tensor = helper.make_tensor_value_info('output', TensorProto.FLOAT, [None, 10])
        
        # Layer 1: Linear(128->64)
        weight1 = np.random.randn(64, 128).astype(np.float32)
        bias1 = np.random.randn(64).astype(np.float32)
        
        weight1_init = numpy_helper.from_array(weight1, name='weight1')
        bias1_init = numpy_helper.from_array(bias1, name='bias1')
        
        matmul1 = helper.make_node('MatMul', ['input', 'weight1'], ['matmul1_out'])
        add1 = helper.make_node('Add', ['matmul1_out', 'bias1'], ['add1_out'])
        relu1 = helper.make_node('Relu', ['add1_out'], ['relu1_out'])
        
        # Layer 2: Linear(64->10)
        weight2 = np.random.randn(10, 64).astype(np.float32)
        bias2 = np.random.randn(10).astype(np.float32)
        
        weight2_init = numpy_helper.from_array(weight2, name='weight2')
        bias2_init = numpy_helper.from_array(bias2, name='bias2')
        
        matmul2 = helper.make_node('MatMul', ['relu1_out', 'weight2'], ['matmul2_out'])
        add2 = helper.make_node('Add', ['matmul2_out', 'bias2'], ['output'])
        
        # Create graph
        graph = helper.make_graph(
            nodes=[matmul1, add1, relu1, matmul2, add2],
            name='test_network',
            inputs=[input_tensor],
            outputs=[output_tensor],
            initializer=[weight1_init, bias1_init, weight2_init, bias2_init]
        )
        
        # Create model
        model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 11)])
        
        # Save model
        onnx.save(model, output_path)
        
        print(f"✓ Created test ONNX model: {output_path}")
        print(f"  Size: {Path(output_path).stat().st_size / 1024:.2f} KB")
        
        return output_path
        
    except ImportError:
        print("⚠ ONNX not installed. Install with: pip install onnx")
        return None


def test_int8_quantization():
    """Test INT8 quantization."""
    print("\n" + "=" * 80)
    print("TEST 1: INT8 Quantization")
    print("=" * 80)
    
    if not QUANT_AVAILABLE:
        print("⚠ Skipping - quantization dependencies not available")
        return None
    
    # Create test model
    model_path = create_test_onnx_model()
    if not model_path:
        return None
    
    # Generate calibration data
    calibration_data = []
    for _ in range(10):
        sample = {
            'input': np.random.randn(1, 128).astype(np.float32)
        }
        calibration_data.append(sample)
    
    print(f"\nQuantizing model to INT8...")
    print(f"  Original model: {model_path}")
    print(f"  Calibration samples: {len(calibration_data)}")
    
    start_time = time.time()
    
    try:
        result = quantize_int8(
            model_path=model_path,
            calibration_data=calibration_data,
            per_channel=False
        )
        
        elapsed = time.time() - start_time
        
        print(f"\n{'='*80}")
        print(f"INT8 Quantization Results:")
        print(f"{'='*80}")
        print(f"  Original size: {result.original_size_kb:.2f} KB")
        print(f"  Quantized size: {result.quantized_size_kb:.2f} KB")
        print(f"  Size reduction: {result.size_reduction_pct:.1f}%")
        print(f"  Accuracy retained: {result.accuracy_retained_pct:.1f}%")
        print(f"  Inference speedup: {result.inference_speedup_pct:.1f}%")
        print(f"  Time taken: {elapsed:.2f}s")
        print(f"  Output: {result.output_path}")
        
        if result.warnings:
            print(f"\n  Warnings:")
            for warning in result.warnings:
                print(f"    - {warning}")
        
        if result.errors:
            print(f"\n  Errors:")
            for error in result.errors:
                print(f"    - {error}")
        
        print(f"{'='*80}")
        
        return result
        
    except Exception as e:
        print(f"✗ INT8 quantization failed: {e}")
        import traceback
        traceback.print_exc()
        return None


def test_fp16_quantization():
    """Test FP16 quantization."""
    print("\n" + "=" * 80)
    print("TEST 2: FP16 Quantization")
    print("=" * 80)
    
    if not QUANT_AVAILABLE:
        print("⚠ Skipping - quantization dependencies not available")
        return None
    
    # Create test model
    model_path = create_test_onnx_model()
    if not model_path:
        return None
    
    print(f"\nQuantizing model to FP16...")
    print(f"  Original model: {model_path}")
    
    start_time = time.time()
    
    try:
        result = quantize_fp16(
            model_path=model_path
        )
        
        elapsed = time.time() - start_time
        
        print(f"\n{'='*80}")
        print(f"FP16 Quantization Results:")
        print(f"{'='*80}")
        print(f"  Original size: {result.original_size_kb:.2f} KB")
        print(f"  Quantized size: {result.quantized_size_kb:.2f} KB")
        print(f"  Size reduction: {result.size_reduction_pct:.1f}%")
        print(f"  Accuracy retained: {result.accuracy_retained_pct:.1f}%")
        print(f"  Inference speedup: {result.inference_speedup_pct:.1f}%")
        print(f"  Time taken: {elapsed:.2f}s")
        print(f"  Output: {result.output_path}")
        
        if result.warnings:
            print(f"\n  Warnings:")
            for warning in result.warnings:
                print(f"    - {warning}")
        
        print(f"{'='*80}")
        
        return result
        
    except Exception as e:
        print(f"✗ FP16 quantization failed: {e}")
        import traceback
        traceback.print_exc()
        return None


def test_model_pruning():
    """Test model pruning."""
    print("\n" + "=" * 80)
    print("TEST 3: Model Pruning")
    print("=" * 80)
    
    if not QUANT_AVAILABLE:
        print("⚠ Skipping - quantization dependencies not available")
        return None
    
    # Create test model
    model_path = create_test_onnx_model()
    if not model_path:
        return None
    
    sparsity_levels = [0.3, 0.5, 0.7]
    
    results = []
    
    for sparsity in sparsity_levels:
        print(f"\nPruning with {sparsity*100:.0f}% target sparsity...")
        
        try:
            output_path = prune_model(
                model_path=model_path,
                sparsity_target=sparsity,
                output_path=f"pruned_{int(sparsity*100)}.onnx"
            )
            
            original_size = Path(model_path).stat().st_size
            pruned_size = Path(output_path).stat().st_size
            actual_reduction = (1 - pruned_size / original_size) * 100
            
            print(f"  ✓ Pruned model: {output_path}")
            print(f"    Original size: {original_size / 1024:.2f} KB")
            print(f"    Pruned size: {pruned_size / 1024:.2f} KB")
            print(f"    Actual reduction: {actual_reduction:.1f}%")
            
            results.append({
                "target_sparsity": sparsity,
                "actual_reduction": actual_reduction,
                "output_path": output_path
            })
        
        except Exception as e:
            print(f"  ✗ Pruning failed at {sparsity*100:.0f}%: {e}")
    
    print(f"\n{'='*80}")
    print(f"Pruning Summary:")
    print(f"{'='*80}")
    for r in results:
        print(f"  Target {r['target_sparsity']*100:.0f}% -> Actual {r['actual_reduction']:.1f}% reduction")
    
    return results


def test_memory_profiling():
    """Test memory profiling."""
    print("\n" + "=" * 80)
    print("TEST 4: Memory Profiling")
    print("=" * 80)
    
    if not QUANT_AVAILABLE:
        print("⚠ Skipping - quantization dependencies not available")
        return None
    
    # Create test model
    model_path = create_test_onnx_model()
    if not model_path:
        return None
    
    print(f"\nProfiling memory usage...")
    print(f"  Model: {model_path}")
    
    try:
        profile = profile_memory_usage(model_path)
        
        print(f"\n{'='*80}")
        print(f"Memory Profile:")
        print(f"{'='*80}")
        print(f"  Total parameters: {profile.total_parameters:,}")
        print(f"  Model size: {profile.model_size_mb:.2f} MB")
        print(f"  Peak memory: {profile.peak_memory_mb:.2f} MB")
        print(f"  Activation memory: {profile.activation_memory_mb:.2f} MB")
        print(f"  Weight memory: {profile.weight_memory_mb:.2f} MB")
        print(f"  Edge compatible (<512MB): {'Yes' if profile.estimated_edge_compatible else 'No'}")
        print(f"{'='*80}")
        
        return profile
        
    except Exception as e:
        print(f"✗ Memory profiling failed: {e}")
        import traceback
        traceback.print_exc()
        return None


def compare_quantization_methods():
    """Compare INT8 vs FP16 quantization."""
    print("\n" + "=" * 80)
    print("COMPARISON: INT8 vs FP16 Quantization")
    print("=" * 80)
    
    if not QUANT_AVAILABLE:
        print("⚠ Skipping - quantization dependencies not available")
        return
    
    # Create test model
    model_path = create_test_onnx_model()
    if not model_path:
        return
    
    # Run both methods
    int8_result = test_int8_quantization()
    fp16_result = test_fp16_quantization()
    
    if int8_result and fp16_result:
        print(f"\n{'='*80}")
        print(f"Side-by-Side Comparison:")
        print(f"{'='*80}")
        print(f"  {'Metric':<30} {'INT8':<15} {'FP16':<15}")
        print(f"  {'-'*60}")
        print(f"  {'Size Reduction':<30} {f'{int8_result.size_reduction_pct:.1f}%':<15} {f'{fp16_result.size_reduction_pct:.1f}%':<15}")
        print(f"  {'Accuracy Retained':<30} {f'{int8_result.accuracy_retained_pct:.1f}%':<15} {f'{fp16_result.accuracy_retained_pct:.1f}%':<15}")
        print(f"  {'Speedup':<30} {f'{int8_result.inference_speedup_pct:.1f}%':<15} {f'{fp16_result.inference_speedup_pct:.1f}%':<15}")
        print(f"{'='*80}")
        
        # Recommendation
        print(f"\nRecommendation:")
        if int8_result.size_reduction_pct > fp16_result.size_reduction_pct:
            print(f"  • Use INT8 for maximum size reduction ({int8_result.size_reduction_pct:.1f}% vs {fp16_result.size_reduction_pct:.1f}%)")
        if int8_result.accuracy_retained_pct < fp16_result.accuracy_retained_pct:
            print(f"  • Use FP16 for better accuracy retention ({fp16_result.accuracy_retained_pct:.1f}% vs {int8_result.accuracy_retained_pct:.1f}%)")
        if int8_result.inference_speedup_pct > fp16_result.inference_speedup_pct:
            print(f"  • Use INT8 for faster inference ({int8_result.inference_speedup_pct:.1f}% vs {fp16_result.inference_speedup_pct:.1f}%)")
        
        print(f"\n  Best choice depends on your priority:")
        print(f"    - Maximum compression: INT8")
        print(f"    - Best accuracy: FP16")
        print(f"    - Balanced: Test both on your specific model")


if __name__ == "__main__":
    print("=" * 80)
    print("TIANNARA MODEL QUANTIZATION INTEGRATION TEST")
    print("=" * 80)
    print(f"Started at: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Run all tests
    test_int8_quantization()
    test_fp16_quantization()
    test_model_pruning()
    test_memory_profiling()
    compare_quantization_methods()
    
    print(f"\n{'='*80}")
    print(f"All quantization tests complete!")
    print(f"Finished at: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*80}")
