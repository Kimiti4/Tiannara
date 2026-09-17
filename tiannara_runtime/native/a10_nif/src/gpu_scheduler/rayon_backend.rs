use super::compute_backend::ComputeBackend;
use rayon::prelude::*;

pub struct RayonBackend;

impl ComputeBackend for RayonBackend {
    fn diffuse(&self, input_tensor: &[f64], coefficient: f64) -> Vec<f64> {
        let len = input_tensor.len();
        if len == 0 {
            return Vec::new();
        }
        
        let mut output = vec![0.0; len];
        
        // Simulated 1D Ring Topology Diffusion for the Rayon parallel backend.
        // In the true CUDA implementation, this uses a proper Adjacency Matrix
        // or Grid topology passed from Elixir.
        output.par_iter_mut().enumerate().for_each(|(i, out)| {
            let left = if i == 0 { len - 1 } else { i - 1 };
            let right = if i == len - 1 { 0 } else { i + 1 };
            
            let current = input_tensor[i];
            let neighbor_avg = (input_tensor[left] + input_tensor[right]) / 2.0;
            
            *out = current + (coefficient * (neighbor_avg - current));
            
            if *out < 0.0 {
                *out = 0.0;
            }
        });
        
        output
    }
}
