use rustler::OwnedBinary;

pub struct TileDispatcher;

impl TileDispatcher {
    /// Dispatches the tensor to the compute backend.
    /// In Phase 3A, this delegates to Rayon. In later phases, this slices
    /// the tensor into tiles and dispatches to multiple CUDA devices.
    pub fn dispatch(
        input_tensor: &OwnedBinary, 
        coefficient: f64, 
        backend: &dyn super::compute_backend::ComputeBackend,
        _pool: &super::tensor_pool::TensorPool
    ) -> Vec<f64> {
        let slice = input_tensor.as_slice();
        
        // Zero-copy reinterpret cast byte slice to f64 slice
        let f64_slice = unsafe {
            std::slice::from_raw_parts(
                slice.as_ptr() as *const f64,
                slice.len() / std::mem::size_of::<f64>(),
            )
        };
        
        backend.diffuse(f64_slice, coefficient)
    }
}
