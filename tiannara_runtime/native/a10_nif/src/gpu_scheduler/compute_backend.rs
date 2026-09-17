pub trait ComputeBackend: Send + Sync {
    fn diffuse(&self, input_tensor: &[f64], coefficient: f64) -> Vec<f64>;
    // Future:
    // fn evolve(&self, ...);
    // fn reduce(&self, ...);
}
