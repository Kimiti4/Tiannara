use std::sync::Mutex;
use std::collections::VecDeque;

pub struct TensorPool {
    pool: Mutex<VecDeque<Vec<f64>>>,
}

impl TensorPool {
    pub fn new() -> Self {
        Self {
            pool: Mutex::new(VecDeque::new()),
        }
    }
    
    pub fn acquire(&self, capacity: usize) -> Vec<f64> {
        let mut p = self.pool.lock().unwrap();
        if let Some(mut vec) = p.pop_front() {
            vec.clear();
            vec.reserve(capacity);
            vec
        } else {
            Vec::with_capacity(capacity)
        }
    }
    
    pub fn release(&self, vec: Vec<f64>) {
        let mut p = self.pool.lock().unwrap();
        // Limit pool size to prevent unbounded memory growth
        if p.len() < 64 {
            p.push_back(vec);
        }
    }
}
