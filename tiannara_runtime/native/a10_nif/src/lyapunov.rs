use rayon::prelude::*;

pub fn lyapunov_v(state_vector: Vec<f64>, gain_matrix: Vec<f64>) -> f64 {
    // Check sizes
    if state_vector.is_empty() || gain_matrix.is_empty() {
        return 0.0;
    }
    
    // Simple lyapunov snapshot calculation V(x) = x^T K x 
    // Here we assume gain_matrix is a diagonal matrix provided as a vector for simplicity
    // in this fast-path integration
    let min_len = state_vector.len().min(gain_matrix.len());
    
    state_vector[..min_len]
        .par_iter()
        .zip(gain_matrix[..min_len].par_iter())
        .map(|(x, k)| x * k * x)
        .sum()
}
