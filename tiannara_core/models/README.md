# Tiannara Core Models Package

Model serialization, quantization, and optimization utilities for edge deployment of Tiannara reasoning components.

## Overview

This package provides tools to convert Tiannara models to optimized formats suitable for deployment on resource-constrained edge devices (target: <512MB memory footprint).

### Key Features

- **ONNX Export**: Framework-agnostic model serialization
- **INT8 Quantization**: 4x size reduction with post-training quantization
- **FP16 Quantization**: 2x size reduction with half-precision
- **Memory Profiling**: Analyze memory usage for edge compatibility
- **Model Pruning**: Remove redundant weights for additional size reduction

## Installation

```bash
pip install onnx onnxruntime onnxconverter-common
```

Or add to your requirements.txt (already included in project root):

```txt
onnx>=1.14.0
onnxruntime>=1.16.0
onnxconverter-common>=1.13.0
```

## Quick Start

### 1. Export Model to ONNX

```python
from tiannara_core.models import export_to_onnx
import numpy as np

# Define your model function
def my_model(x, weights):
    return np.dot(x, weights) + 0.1

# Define input signature
input_signature = {
    'x': ((10, 20), np.float32),
    'weights': ((20, 5), np.float32)
}

# Export to ONNX
export_to_onnx(
    my_model,
    "model.onnx",
    input_signature=input_signature
)
```

### 2. Validate Exported Model

```python
from tiannara_core.models import validate_onnx_model

# Validate with test data
test_data = {
    'x': np.random.randn(10, 20).astype(np.float32),
    'weights': np.random.randn(20, 5).astype(np.float32)
}

result = validate_onnx_model(
    "model.onnx",
    test_inputs=test_data,
    original_func=my_model
)

print(f"Valid: {result.is_valid}")
print(f"Accuracy: {result.accuracy_retained:.2f}%")
print(f"Inference time: {result.inference_time_ms:.2f} ms")
```

### 3. Quantize to INT8

```python
from tiannara_core.models import quantize_int8

# Prepare calibration data
calibration_data = [
    {'x': np.random.randn(10, 20).astype(np.float32),
     'weights': np.random.randn(20, 5).astype(np.float32)}
    for _ in range(10)
]

# Quantize
result = quantize_int8(
    "model.onnx",
    calibration_data=calibration_data
)

print(f"Size reduction: {result.size_reduction_pct:.1f}%")
print(f"Accuracy retained: {result.accuracy_retained_pct:.2f}%")
print(f"Speedup: {result.inference_speedup_pct:.1f}%")
```

### 4. Quantize to FP16

```python
from tiannara_core.models import quantize_fp16

result = quantize_fp16("model.onnx")

print(f"Size reduction: {result.size_reduction_pct:.1f}%")
print(f"Output: {result.output_path}")
```

### 5. Profile Memory Usage

```python
from tiannara_core.models import profile_memory_usage

profile = profile_memory_usage("model.onnx")

print(f"Total parameters: {profile.total_parameters:,}")
print(f"Peak memory: {profile.peak_memory_mb:.2f} MB")
print(f"Edge compatible: {profile.estimated_edge_compatible}")
```

### 6. Prune Model

```python
from tiannara_core.models import prune_model

pruned_path = prune_model(
    "model.onnx",
    sparsity_target=0.3  # Remove 30% of weights
)

print(f"Pruned model saved to: {pruned_path}")
```

## Complete Pipeline Example

See [`test_quantization.py`](tiannara_core/models/test_quantization.py) for a complete example that demonstrates the entire workflow:

```bash
python tiannara_core/models/test_quantization.py
```

## Quantization Strategies

### INT8 vs FP16

| Feature | INT8 | FP16 |
|---------|------|------|
| **Size Reduction** | ~75% (4x) | ~50% (2x) |
| **Accuracy Retention** | 95-99% | 99-99.5% |
| **Speedup** | 2-4x | 1.5-2x |
| **Hardware Support** | Most CPUs/GPUs | GPUs with FP16 support |
| **Best For** | Maximum size reduction | Balance of accuracy/size |

### When to Use Each

**Use INT8 when:**
- Deploying to very constrained devices (<256MB RAM)
- Maximum size reduction is critical
- 95%+ accuracy is acceptable

**Use FP16 when:**
- Target devices support FP16 (modern GPUs)
- Need better accuracy than INT8
- 2x size reduction is sufficient

## Edge Deployment Targets

### Memory Budget (<512MB Total)

| Component | Budget |
|-----------|--------|
| Model Weights | <200 MB |
| Activations | <200 MB |
| Runtime Overhead | <112 MB |

### Recommended Settings

For edge deployment targeting <512MB:

1. **Quantize to INT8** for maximum size reduction
2. **Prune model** with 30% sparsity target
3. **Profile memory** to verify <512MB peak usage
4. **Validate accuracy** remains >95%

## API Reference

### `export_to_onnx(model, output_path, input_signature, **kwargs)`

Export a model to ONNX format.

**Parameters:**
- `model`: Model to export (callable or framework-specific model)
- `output_path`: Path for ONNX file
- `input_signature`: Dict mapping input names to (shape, dtype) tuples
- `**kwargs`: Additional arguments (sample_inputs, config, etc.)

**Returns:** Path to exported ONNX model

---

### `validate_onnx_model(model_path, test_inputs, original_func)`

Validate an exported ONNX model.

**Parameters:**
- `model_path`: Path to ONNX model
- `test_inputs`: Test inputs for validation
- `original_func`: Original function to compare against

**Returns:** `ValidationResult` with accuracy, performance metrics

---

### `quantize_int8(model_path, output_path, calibration_data, per_channel)`

Quantize model to INT8 precision.

**Parameters:**
- `model_path`: Path to FP32 ONNX model
- `output_path`: Path for quantized model (optional)
- `calibration_data`: Sample data for calibration (recommended)
- `per_channel`: Use per-channel quantization (default: False)

**Returns:** `QuantizationResult` with size, accuracy, speedup metrics

---

### `quantize_fp16(model_path, output_path)`

Quantize model to FP16 precision.

**Parameters:**
- `model_path`: Path to FP32 ONNX model
- `output_path`: Path for quantized model (optional)

**Returns:** `QuantizationResult` with metrics

---

### `profile_memory_usage(model_path)`

Profile memory usage of a model.

**Parameters:**
- `model_path`: Path to ONNX model

**Returns:** `MemoryProfile` with detailed memory breakdown

---

### `prune_model(model_path, output_path, sparsity_target)`

Prune model weights to reduce size.

**Parameters:**
- `model_path`: Path to ONNX model
- `output_path`: Path for pruned model (optional)
- `sparsity_target`: Fraction of weights to prune (0.0-1.0)

**Returns:** Path to pruned model

## Troubleshooting

### Import Errors

If you see `ImportError` for ONNX modules:

```bash
pip install onnx onnxruntime onnxconverter-common
```

### Accuracy Loss After Quantization

If accuracy drops below 95%:

1. **Provide more calibration data** (at least 100 samples)
2. **Use per-channel quantization** (`per_channel=True`)
3. **Try FP16 instead of INT8** for better accuracy retention
4. **Reduce sparsity target** if pruning (try 0.2 instead of 0.3)

### Model Too Large for Edge

If peak memory >512MB:

1. **Apply INT8 quantization** (~4x reduction)
2. **Prune with higher sparsity** (0.4-0.5)
3. **Reduce model architecture** (fewer layers/parameters)
4. **Combine quantization + pruning** for maximum reduction

## Future Enhancements

Planned features:

- [ ] PyTorch model export support
- [ ] JAX model export support
- [ ] Quantization-aware training (QAT) pipeline
- [ ] Knowledge distillation for model compression
- [ ] Automatic mixed precision (AMP) support
- [ ] Edge device benchmarking suite

## References

- [ONNX Documentation](https://onnx.ai/)
- [ONNX Runtime Quantization](https://onnxruntime.ai/docs/performance/quantization.html)
- [Model Optimization Guide](https://onnxruntime.ai/docs/performance/model-optimizations.html)

## License

Same license as Tiannara MindCache project.
