mod drift;
mod lyapunov;
mod shared;
mod gpu_scheduler;

use rustler::{Env, Term, NifResult, ResourceArc};
use shared::StateResource;

pub fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource!(StateResource, env);
    gpu_scheduler::Scheduler::start();
    true
}

#[rustler::nif]
fn allocate_state(total_size: usize, shard_size: usize) -> ResourceArc<StateResource> {
    ResourceArc::new(StateResource::new(total_size, shard_size))
}

#[rustler::nif]
fn update_shard(resource: ResourceArc<StateResource>, shard_idx: usize, data: Vec<f64>) -> NifResult<rustler::Atom> {
    match resource.update_shard(shard_idx, data) {
        Ok(_) => Ok(rustler::types::atom::ok()),
        Err(e) => Err(rustler::Error::Term(Box::new(e))),
    }
}

#[rustler::nif]
fn read_shard(resource: ResourceArc<StateResource>, shard_idx: usize) -> NifResult<Vec<f64>> {
    match resource.read_shard(shard_idx) {
        Ok(data) => Ok(data),
        Err(e) => Err(rustler::Error::Term(Box::new(e))),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn compute_drift_shared(resource: ResourceArc<StateResource>, window_size: usize) -> NifResult<Vec<f64>> {
    match resource.compute_drift(window_size) {
        Ok(drift) => Ok(drift),
        Err(e) => Err(rustler::Error::Term(Box::new(e))),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn lyapunov_shared(resource: ResourceArc<StateResource>, gain_matrix: Vec<f64>) -> NifResult<f64> {
    match resource.lyapunov_v(&gain_matrix) {
        Ok(v) => Ok(v),
        Err(e) => Err(rustler::Error::Term(Box::new(e))),
    }
}

// Keep the old ones just in case
#[rustler::nif(schedule = "DirtyCpu")]
fn compute_drift(tensor_data: Vec<f64>, window_size: usize) -> NifResult<Vec<f64>> {
    Ok(drift::compute_drift(tensor_data, window_size))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn lyapunov_v(state_vector: Vec<f64>, gain_matrix: Vec<f64>) -> NifResult<f64> {
    Ok(lyapunov::lyapunov_v(state_vector, gain_matrix))
}

#[rustler::nif]
fn submit_diffusion_job(
    binary_tensor: rustler::Binary,
    coefficient: f64,
    ref_id: String,
    caller_pid: rustler::LocalPid
) -> rustler::Atom {
    let mut owned_binary = rustler::OwnedBinary::new(binary_tensor.len()).unwrap();
    owned_binary.as_mut_slice().copy_from_slice(binary_tensor.as_slice());
    
    let job = gpu_scheduler::work_queue::Job {
        command: gpu_scheduler::work_queue::JobCommand::Diffuse { diffusion_coefficient: coefficient },
        input_tensor: owned_binary,
        caller_pid,
        ref_id
    };
    
    match gpu_scheduler::Scheduler::submit_job(job) {
        Ok(_) => rustler::types::atom::ok(),
        Err(_) => rustler::types::atom::error()
    }
}

rustler::init!("Elixir.Tiannara.Native.A10", load = on_load);