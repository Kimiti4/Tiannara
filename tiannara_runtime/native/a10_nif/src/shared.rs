use std::sync::RwLock;
use rayon::prelude::*;

pub struct StateResource {
    pub shards: Vec<RwLock<Vec<f64>>>,
    pub shard_size: usize,
}

impl StateResource {
    pub fn new(total_size: usize, shard_size: usize) -> Self {
        let num_shards = (total_size + shard_size - 1) / shard_size;
        let mut shards = Vec::with_capacity(num_shards);
        
        for _ in 0..num_shards {
            shards.push(RwLock::new(vec![0.0; shard_size]));
        }
        
        StateResource {
            shards,
            shard_size,
        }
    }

    pub fn update_shard(&self, shard_idx: usize, data: Vec<f64>) -> Result<(), String> {
        if shard_idx >= self.shards.len() {
            return Err(format!("Shard index out of bounds: {} >= {}", shard_idx, self.shards.len()));
        }
        
        let mut shard = self.shards[shard_idx].write().map_err(|_| "PoisonError")?;
        *shard = data;
        Ok(())
    }

    pub fn read_shard(&self, shard_idx: usize) -> Result<Vec<f64>, String> {
        if shard_idx >= self.shards.len() {
            return Err("Shard index out of bounds".to_string());
        }
        
        let shard = self.shards[shard_idx].read().map_err(|_| "PoisonError")?;
        Ok(shard.clone())
    }

    pub fn compute_drift(&self, window_size: usize) -> Result<Vec<f64>, String> {
        // Mode A: Direct compute read-only parallel
        let drifts: Result<Vec<Vec<f64>>, String> = self.shards.par_iter().map(|shard_lock| {
            let shard = shard_lock.read().map_err(|_| "PoisonError".to_string())?;
            let effective_window = window_size.min(shard.len());
            if effective_window == 0 {
                return Ok(vec![]);
            }
            
            let drift: Vec<f64> = shard
                .windows(effective_window)
                .map(|w| w.iter().sum::<f64>() / (effective_window as f64))
                .collect();
            Ok(drift)
        }).collect();
        
        let mut final_drift = Vec::new();
        for mut d in drifts? {
            final_drift.append(&mut d);
        }
        Ok(final_drift)
    }

    pub fn lyapunov_v(&self, gain_matrix: &[f64]) -> Result<f64, String> {
        // Mode A: Direct compute read-only parallel for Lyapunov V(x)
        let result: Result<f64, String> = self.shards.par_iter().enumerate().map(|(i, shard_lock)| {
            let shard = shard_lock.read().map_err(|_| "PoisonError".to_string())?;
            let offset = i * self.shard_size;
            
            let mut v = 0.0;
            for (j, &x) in shard.iter().enumerate() {
                let k_idx = offset + j;
                let k = if k_idx < gain_matrix.len() { gain_matrix[k_idx] } else { 1.0 };
                v += x * k * x;
            }
            Ok(v)
        }).reduce(|| Ok(0.0), |a, b| {
            Ok(a? + b?)
        });
        
        result
    }
}
