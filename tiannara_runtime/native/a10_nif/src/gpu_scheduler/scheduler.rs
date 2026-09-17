use std::sync::{Arc, Mutex, OnceLock};
use std::thread;
use std::sync::mpsc::{channel, Sender, Receiver};
use rustler::{Encoder, OwnedEnv};
use super::tensor_pool::TensorPool;
use super::rayon_backend::RayonBackend;
use super::tile_dispatcher::TileDispatcher;

static JOB_SENDER: OnceLock<Mutex<Sender<super::work_queue::Job>>> = OnceLock::new();

pub struct Scheduler;

impl Scheduler {
    pub fn start() {
        let (tx, rx): (Sender<super::work_queue::Job>, Receiver<super::work_queue::Job>) = channel();
        
        let _ = JOB_SENDER.set(Mutex::new(tx));
        
        let pool = Arc::new(TensorPool::new());
        let backend = Arc::new(RayonBackend);
        
        thread::spawn(move || {
            println!("🧠 [Rust Native] GPU Scheduler Thread Booted.");
            loop {
                match rx.recv() {
                    Ok(job) => {
                        let pool = Arc::clone(&pool);
                        let backend = Arc::clone(&backend);
                        
                        match job.command {
                            super::work_queue::JobCommand::Diffuse { diffusion_coefficient } => {
                                let output_vec = TileDispatcher::dispatch(
                                    &job.input_tensor, 
                                    diffusion_coefficient, 
                                    &*backend,
                                    &pool
                                );
                                
                                let mut owned_env = OwnedEnv::new();
                                owned_env.send_and_clear(&job.caller_pid, |env| {
                                    let byte_len = output_vec.len() * std::mem::size_of::<f64>();
                                    let mut erl_bin = rustler::NewBinary::new(env, byte_len);
                                    
                                    unsafe {
                                        std::ptr::copy_nonoverlapping(
                                            output_vec.as_ptr() as *const u8,
                                            erl_bin.as_mut_slice().as_mut_ptr(),
                                            byte_len
                                        );
                                    }
                                    
                                    pool.release(output_vec);
                                    
                                    let ok_atom = rustler::Atom::from_str(env, "ok").unwrap();
                                    let result = erl_bin.into();
                                    
                                    rustler::types::tuple::make_tuple(env, &[
                                        ok_atom.to_term(env),
                                        job.ref_id.encode(env),
                                        result
                                    ])
                                });
                            }
                        }
                    },
                    Err(_) => {
                        println!("🧠 [Rust Native] GPU Scheduler Thread Shutting Down.");
                        break;
                    }
                }
            }
        });
    }
    
    pub fn submit_job(job: super::work_queue::Job) -> Result<(), String> {
        if let Some(tx_mutex) = JOB_SENDER.get() {
            let tx = tx_mutex.lock().unwrap();
            tx.send(job).map_err(|e| format!("Failed to send job: {}", e))
        } else {
            Err("Scheduler not started".to_string())
        }
    }
}
