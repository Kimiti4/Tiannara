use rustler::NifStruct;
use rand::Rng;

#[derive(NifStruct, Clone, Debug)]
#[module = "Tiannara.PhysicsLaw"]
pub struct PhysicsLaw {
    pub diffusion: f32,
    pub decay: f32,
    pub coupling: f32,
    pub entropy_bias: f32,
    pub novelty_response: f32,
}

#[derive(NifStruct, Clone)]
#[module = "Tiannara.OlefField"]
pub struct OlefField {
    pub pressure: Vec<f32>,
    pub entropy: Vec<f32>,
    pub curvature: Vec<f32>,
    pub novelty: Vec<f32>,
    pub semantic: Vec<f32>,
    pub width: usize,
    pub height: usize,
    pub tick: u64,
    pub population: Vec<PhysicsLaw>,
}

#[rustler::nif]
pub fn initialize(width: usize, height: usize) -> OlefField {
    let size = width * height;
    
    let pop = vec![
        PhysicsLaw { diffusion: 0.18, decay: 0.015, coupling: 0.25, entropy_bias: 0.10, novelty_response: 0.15 },
        PhysicsLaw { diffusion: 0.20, decay: 0.020, coupling: 0.30, entropy_bias: 0.05, novelty_response: 0.20 },
        PhysicsLaw { diffusion: 0.15, decay: 0.010, coupling: 0.15, entropy_bias: 0.15, novelty_response: 0.10 },
        PhysicsLaw { diffusion: 0.25, decay: 0.030, coupling: 0.40, entropy_bias: 0.02, novelty_response: 0.30 },
    ];

    OlefField {
        pressure: vec![5.0; size],
        entropy: vec![0.5; size],
        curvature: vec![0.0; size],
        novelty: vec![0.0; size],
        semantic: vec![0.5; size],
        width,
        height,
        tick: 0,
        population: pop,
    }
}

fn simulate_with_law(field: &OlefField, law: &PhysicsLaw) -> OlefField {
    let mut temp_field = field.clone();
    let w = temp_field.width;
    let h = temp_field.height;
    
    let mut next_pressure = temp_field.pressure.clone();
    let mut next_entropy = temp_field.entropy.clone();
    let mut next_semantic = temp_field.semantic.clone();

    for y in 1..h - 1 {
        let row = y * w;
        for x in 1..w - 1 {
            let i = row + x;
            let p = temp_field.pressure[i];
            let pn = temp_field.pressure[i - w];
            let ps = temp_field.pressure[i + w];
            let pe = temp_field.pressure[i + 1];
            let pw = temp_field.pressure[i - 1];

            let lap_p = pn + ps + pe + pw - 4.0 * p;
            let e = temp_field.entropy[i];
            let n = temp_field.novelty[i];
            let s = temp_field.semantic[i];

            let new_p = p + law.diffusion * lap_p - law.decay * p + law.coupling * n;
            let new_e = e + law.diffusion * 0.7 * lap_p - law.entropy_bias * s + law.novelty_response * n;
            let new_s = s + law.coupling * 0.5 * lap_p - e * 0.05;

            next_pressure[i] = new_p;
            next_entropy[i] = new_e;
            next_semantic[i] = new_s;
        }
    }
    temp_field.pressure = next_pressure;
    temp_field.entropy = next_entropy;
    temp_field.semantic = next_semantic;
    temp_field
}

fn compute_fitness(field: &OlefField) -> f32 {
    let total_entropy: f32 = field.entropy.iter().sum();
    let avg_entropy = total_entropy / (field.entropy.len() as f32);
    let stability = 1.0 - avg_entropy;
    
    let avg_semantic: f32 = field.semantic.iter().sum::<f32>() / (field.semantic.len() as f32);
    let coherence = avg_semantic;
    
    let novelty = field.pressure.iter().map(|&x| (x - 5.0).abs()).sum::<f32>() / (field.pressure.len() as f32 * 5.0);

    stability * 0.4 + novelty * 0.3 + coherence * 0.3
}

fn evolve_laws(population: Vec<PhysicsLaw>, field: &OlefField) -> Vec<PhysicsLaw> {

    // 1. Evaluate
    let mut scores = Vec::new();
    for law in &population {
        let future_field = simulate_with_law(field, law);
        scores.push(compute_fitness(&future_field));
    }

    // 2. Select
    let mut sorted: Vec<(PhysicsLaw, f32)> = population.into_iter().zip(scores).collect();
    sorted.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

    // Keep top half
    let survivors: Vec<PhysicsLaw> = sorted.iter().take(sorted.len() / 2).map(|(law, _)| law.clone()).collect();

    // 3. Recombine & Mutate to restore population
    let mut next_gen = survivors.clone();
    
    while next_gen.len() < sorted.len() {
        let parent_a = &survivors[(rand::random::<u32>() as usize) % survivors.len()];
        let parent_b = &survivors[(rand::random::<u32>() as usize) % survivors.len()];
        
        let mut child = PhysicsLaw {
            diffusion: (parent_a.diffusion + parent_b.diffusion) / 2.0,
            decay: (parent_a.decay.max(0.0001) * parent_b.decay.max(0.0001)).sqrt(),
            coupling: parent_a.coupling,
            entropy_bias: parent_b.entropy_bias,
            novelty_response: (parent_a.novelty_response + parent_b.novelty_response) / 2.0,
        };
        
        // Mutate
        child.diffusion += (rand::random::<f32>() - 0.5) * 0.05;
        child.decay += (rand::random::<f32>() - 0.5) * 0.01;
        child.coupling += (rand::random::<f32>() - 0.5) * 0.04;
        child.entropy_bias += (rand::random::<f32>() - 0.5) * 0.02;
        child.novelty_response += (rand::random::<f32>() - 0.5) * 0.06;

        // Clamp
        child.diffusion = child.diffusion.clamp(0.01, 0.5);
        child.decay = child.decay.clamp(0.001, 0.1);
        child.coupling = child.coupling.clamp(0.0, 1.0);
        child.entropy_bias = child.entropy_bias.clamp(0.0, 1.0);
        child.novelty_response = child.novelty_response.clamp(0.0, 1.0);

        next_gen.push(child);
    }

    next_gen
}

#[rustler::nif]
pub fn step(field: OlefField) -> OlefField {
    let mut field = field;
    field.tick += 1;

    // Run SOPL evolution every 10 ticks to prevent extreme CPU stalling
    if field.tick % 10 == 0 {
        field.population = evolve_laws(field.population.clone(), &field);
    }

    let w = field.width;
    let h = field.height;
    let pop_size = field.population.len();
    
    let mut next_pressure = field.pressure.clone();
    let mut next_entropy = field.entropy.clone();
    let mut next_semantic = field.semantic.clone();

    for y in 1..h - 1 {
        let row = y * w;
        for x in 1..w - 1 {
            let i = row + x;

            let law_idx = (x * pop_size / w).min(pop_size - 1);
            let law = &field.population[law_idx];

            let p = field.pressure[i];
            let pn = field.pressure[i - w];
            let ps = field.pressure[i + w];
            let pe = field.pressure[i + 1];
            let pw = field.pressure[i - 1];

            // Smooth boundary issues by linearly interpolating Laplacian across boundaries
            // We skip exact smoothing for raw speed, relying on decay to handle boundary stress.
            let lap_p = pn + ps + pe + pw - 4.0 * p;
            
            let e = field.entropy[i];
            let n = field.novelty[i];
            let s = field.semantic[i];

            let new_p = p + law.diffusion * lap_p - law.decay * p + law.coupling * n;
            let new_e = e + law.diffusion * 0.7 * lap_p - law.entropy_bias * s + law.novelty_response * n;
            let new_s = s + law.coupling * 0.5 * lap_p - e * 0.05;

            next_pressure[i] = new_p;
            next_entropy[i] = new_e;
            next_semantic[i] = new_s;
        }
    }
    
    field.pressure = next_pressure;
    field.entropy = next_entropy;
    field.semantic = next_semantic;
    
    field
}

#[rustler::nif]
pub fn inject_novelty(field: OlefField, tick: u64) -> OlefField {
    let mut field = field;
    let phase = (tick as f32 * 0.01).sin();

    for i in 0..field.novelty.len() {
        let noise = ((i as f32 * 12.9898 + phase).sin() * 43758.5453).fract();
        field.novelty[i] = 0.5 * field.novelty[i] + 0.5 * phase * noise;
    }
    
    field
}

#[rustler::nif]
pub fn clamp_pressure(field: OlefField) -> OlefField {
    let mut field = field;
    for p in field.pressure.iter_mut() {
        *p = p.clamp(0.0, 10.0);
    }
    field
}

#[rustler::nif]
pub fn apply_causal_smoothing(field: OlefField, prev_curvature: Vec<f32>) -> OlefField {
    let mut field = field;
    if field.curvature.len() == prev_curvature.len() {
        for (c, p) in field.curvature.iter_mut().zip(prev_curvature.iter()) {
            *c = 0.7 * (*c) + 0.3 * p;
        }
    }
    field
}

rustler::init!("Elixir.Tiannara.OlefNif");
