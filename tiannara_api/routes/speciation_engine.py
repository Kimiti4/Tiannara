"""
Chimeric Speciation Engine - GPU-Accelerated UMAP & Species Detection

Detects emergent species by clustering worlds based on genome similarity.
Uses cuML (RAPIDS) for GPU acceleration when available, falls back to CPU.

Subscribes to NATS telemetry stream and publishes processed speciation data.
"""

import os
import json
import numpy as np
from nats.aio.client import Client as NATS
import asyncio

import logging

logger = logging.getLogger(__name__)

# Attempt to load GPU-accelerated RAPIDS libraries; fallback to CPU if unavailable
try:
    from cuml.manifold import UMAP
    from cuml.cluster import HDBSCAN
    GPU_ACCELERATED = True
    logger.info("[✓] Using GPU-accelerated cuML (RAPIDS)")
except ImportError:
    from umap import UMAP
    from sklearn.cluster import HDBSCAN
    GPU_ACCELERATED = False
    logger.info("[✓] Using CPU-based umap-learn + sklearn")


class ChimericSpeciationEngine:
    """
    Detects chimeric hybrid zones and stable species clusters in real-time.
    
    Pipeline:
    1. Receive batched world telemetry from Elixir via NATS
    2. Extract multi-dimensional feature vectors (fitness, entropy, CAL, CIS, mutation_rate)
    3. Project into 2D space using UMAP dimensionality reduction
    4. Cluster using HDBSCAN density-based algorithm
    5. Identify chimeric anomalies (outliers between clusters)
    6. Publish results back to NATS for visualization
    """
    
    def __init__(self, nats_url="nats://127.0.0.1:4222"):
        self.nats_url = nats_url
        self.nc = NATS()
        
        # Configure UMAP for low-dimensional evolutionary tracking
        self.reducer = UMAP(
            n_neighbors=15,           # Local neighborhood size
            n_components=2,           # Project to 2D for visualization
            min_dist=0.1,             # Minimum distance between embedded points
            metric='euclidean',       # Distance metric
            random_state=42           # Reproducibility
        )
        
        # HDBSCAN clusters worlds into distinct "emergent species" branches
        self.clusterer = HDBSCAN(
            min_cluster_size=3,                    # Minimum species population
            metric='euclidean',
            cluster_selection_method='eom'         # Excess of Mass method
        )
        
        logger.info(f"[*] Chimeric Speciation Engine initialized (GPU: {GPU_ACCELERATED})")

    async def connect(self):
        """Connect to NATS and subscribe to telemetry stream."""
        await self.nc.connect(self.nats_url)
        logger.info(f"[*] Connected to NATS at {self.nats_url}")
        await self.nc.subscribe(
            "tiannara.analytics.speciation.raw",
            cb=self.on_telemetry_receive
        )
        logger.info("[*] Subscribed to tiannara.analytics.speciation.raw")

    async def on_telemetry_receive(self, msg):
        """
        Handle incoming telemetry batch from Elixir TelemetryBuffer.
        
        Payload format:
        {
          "generation": 42,
          "data": {
            "W1": [0.85, 0.12, 0.45, 0.67, 0.03],
            "W2": [0.72, 0.34, 0.51, 0.58, 0.05],
            ...
          }
        }
        """
        try:
            payload = json.loads(msg.data.decode())
            generation = payload["generation"]
            world_map = payload["data"]
            
            if len(world_map) < 4:
                logger.info(f"[!] Generation {generation}: Insufficient data ({len(world_map)} worlds)")
                return

            # 1. Parse raw data into structural matrices
            world_ids = list(world_map.keys())
            features = np.array(list(world_map.values()), dtype=np.float32)
            
            logger.info(f"[*] Processing generation {generation}: {len(world_ids)} worlds, {features.shape[1]} features")

            # 2. Project into 2D Speciation Space using UMAP
            try:
                embeddings = self.reducer.fit_transform(features)
                labels = self.clusterer.fit_predict(embeddings)
            except Exception as e:
                logger.error(f"[!] Embedding error: {e}")
                return

            # 3. Analyze lineages and isolate Chimeric Hybrid zones
            await self.process_and_publish_species(generation, world_ids, embeddings, labels, features)
            
        except Exception as e:
            logger.error(f"[!] Error processing telemetry: {e}")

    async def process_and_publish_species(self, gen, world_ids, embeddings, labels, features):
        """
        Analyze clustering results and identify chimeric anomalies.
        
        Chimeric hybrids are outliers (label=-1) that exist between tight clusters,
        indicating ongoing subsystem recombination or horizontal law transfer.
        """
        resolved_clusters = {}
        chimeric_anomalies = []

        for idx, w_id in enumerate(world_ids):
            cluster_id = int(labels[idx])
            coords = embeddings[idx].tolist()
            
            if cluster_id not in resolved_clusters:
                resolved_clusters[cluster_id] = []
            
            resolved_clusters[cluster_id].append(w_id)

            # Detect Chimeric Fusions: Checking if a world identifies as an outlier (-1)
            # but maintains structural profile alignment to multiple ancestral nodes
            if cluster_id == -1:
                # Calculate distance matrix to find inter-species "bridges"
                distances_to_clusters = self._calculate_cluster_distances(embeddings[idx], embeddings, labels)
                
                chimeric_anomalies.append({
                    "world_id": w_id,
                    "coordinates": coords,
                    "hybrid_signature": True,
                    "nearest_clusters": distances_to_clusters[:3]  # Top 3 nearest clusters
                })

        # Assemble the clean data payload for the Evolution Debugger UI
        output_payload = {
            "generation": gen,
            "coordinates": {w_id: embeddings[idx].tolist() for idx, w_id in enumerate(world_ids)},
            "species_assignments": {w_id: int(labels[idx]) for idx, w_id in enumerate(world_ids)},
            "chimeric_bridges": chimeric_anomalies,
            "cluster_summary": {
                str(cluster_id): {
                    "population": len(members),
                    "members": members
                }
                for cluster_id, members in resolved_clusters.items()
            }
        }

        # Stream back into NATS for the Live DAG and WebGL pipelines to consume
        await self.nc.publish(
            "tiannara.analytics.speciation.processed",
            json.dumps(output_payload).encode()
        )
        
        # Log summary
        num_species = len([c for c in resolved_clusters.keys() if c != -1])
        num_chimeras = len(chimeric_anomalies)
        logger.info(f"[✓] Gen {gen}: {num_species} species, {num_chimeras} chimeric bridges detected")

    def _calculate_cluster_distances(self, point, all_points, labels):
        """
        Calculate average distance from a point to each cluster centroid.
        Used to identify which species a chimeric world is closest to.
        """
        unique_labels = set(labels)
        distances = []
        
        for label in unique_labels:
            if label == -1:
                continue
            
            # Get cluster members
            mask = labels == label
            cluster_points = all_points[mask]
            
            if len(cluster_points) == 0:
                continue
            
            # Calculate centroid
            centroid = np.mean(cluster_points, axis=0)
            
            # Calculate Euclidean distance
            dist = np.linalg.norm(point - centroid)
            distances.append((int(label), float(dist)))
        
        # Sort by distance (ascending)
        distances.sort(key=lambda x: x[1])
        return distances


async def main():
    """Main entry point for the speciation engine."""
    nats_url = os.getenv("NATS_URL", "nats://127.0.0.1:4222")
    engine = ChimericSpeciationEngine(nats_url=nats_url)
    await engine.connect()
    
    logger.info("[*] Speciation Engine running. Press Ctrl+C to stop.")
    
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        logger.info("\n[*] Shutting down...")
        await engine.nc.close()


if __name__ == "__main__":
    asyncio.run(main())
