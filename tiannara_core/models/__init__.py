"""
Tiannara Core Models Package

Provides model serialization, quantization, and optimization utilities
for edge deployment of Tiannara reasoning components.

Key Features:
- ONNX export for framework-agnostic model serialization
- INT8/FP16 quantization for reduced memory footprint
- Model pruning and knowledge distillation
- Memory profiling and optimization

Usage:
    from tiannara_core.models import onnx_export, quantization
    
    # Export model to ONNX
    onnx_export.export_to_onnx(model, "model.onnx")
    
    # Quantize model
    quantized_model = quantization.quantize_int8(model)
"""

from .onnx_export import export_to_onnx, validate_onnx_model
from .quantization import (
    quantize_int8, 
    quantize_fp16, 
    profile_memory_usage,
    prune_model
)

__all__ = [
    'export_to_onnx',
    'validate_onnx_model', 
    'quantize_int8',
    'quantize_fp16',
    'profile_memory_usage',
    'prune_model'
]
