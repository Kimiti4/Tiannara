use rustler::{LocalPid, OwnedBinary};

pub enum JobCommand {
    Diffuse {
        diffusion_coefficient: f64,
    },
}

pub struct Job {
    pub command: JobCommand,
    pub input_tensor: OwnedBinary,
    pub caller_pid: LocalPid,
    pub ref_id: String,
}
