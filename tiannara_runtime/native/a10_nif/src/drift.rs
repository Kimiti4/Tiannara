use rayon::prelude::*;

pub fn compute_drift(tensor_data: Vec<f64>, window_size: usize) -> Vec<f64> {
    if tensor_data.is_empty() || window_size == 0 {
        return vec![];
    }
    
    // Fallback if tensor_data is smaller than window_size
    let effective_window = window_size.min(tensor_data.len());
    
    // SIMD parallel window fast-paths
    tensor_data
        .par_windows(effective_window)
        .map(|window| {
            // Compute drift (moving average as placeholder for actual tensor math)
            let sum: f64 = window.iter().sum();
            sum / (effective_window as f64)
        })
        .collect()
}
