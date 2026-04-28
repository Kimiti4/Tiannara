"""
Neural Trace Embeddings (DEG Core)

Differentiable Execution Gradients implementation for learning representations
through actual program execution traces.
"""

import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np
from typing import List, Dict, Any, Optional
import logging


class TraceEmbedder(nn.Module):
    """Neural network for embedding execution traces into latent space."""
    
    def __init__(self, input_dim=10, hidden_dim=64, latent_dim=32):
        super().__init__()

        self.encoder = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim // 2),
            nn.ReLU(),
            nn.Linear(hidden_dim // 2, latent_dim)
        )

        self.decoder = nn.Sequential(
            nn.Linear(latent_dim, hidden_dim // 2),
            nn.ReLU(),
            nn.Linear(hidden_dim // 2, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, input_dim)
        )

    def forward(self, x):
        z = self.encoder(x)
        return z, self.decoder(z)


class DEGTrainer:
    """Trainer for Differentiable Execution Gradients model."""
    
    def __init__(self, input_dim=10, hidden_dim=64, latent_dim=32):
        self.model = TraceEmbedder(input_dim, hidden_dim, latent_dim)
        self.optimizer = optim.Adam(self.model.parameters(), lr=1e-3)
        self.loss_fn = nn.MSELoss()
        self.logger = logging.getLogger("tiannara.deg.trainer")

    def vectorize_trace(self, trace: List[Dict[str, Any]]) -> torch.Tensor:
        """
        Convert execution trace dictionaries to numeric vectors.
        
        Args:
            trace: List of trace steps, each with various attributes
            
        Returns:
            Tensor of shape (sequence_length, input_dim)
        """
        if not trace:
            # Return zeros if no trace
            return torch.zeros((1, 10), dtype=torch.float32)
        
        vec = []
        for step in trace:
            # Extract numerical values from step, pad/truncate to input_dim
            step_vec = []
            
            # Extract common fields that can be converted to numbers
            for key, value in step.items():
                if isinstance(value, (int, float)):
                    step_vec.append(float(value))
                elif isinstance(value, str):
                    # Convert string to hash for embedding
                    step_vec.append(float(hash(value) % 10000) / 10000.0)
                elif isinstance(value, bool):
                    step_vec.append(1.0 if value else 0.0)
                else:
                    # For other types, use hash
                    step_vec.append(float(hash(str(value)) % 10000) / 10000.0)
            
            # Pad or truncate to input_dim
            if len(step_vec) < 10:
                step_vec.extend([0.0] * (10 - len(step_vec)))
            else:
                step_vec = step_vec[:10]
                
            vec.append(step_vec)
        
        return torch.tensor(vec, dtype=torch.float32)

    def train_step(self, trace: List[Dict[str, Any]]) -> tuple:
        """
        Perform one training step on a trace.
        
        Args:
            trace: Execution trace to train on
            
        Returns:
            Tuple of (latent_embeddings, loss_value)
        """
        if not trace:
            return torch.zeros((1, 32)), 0.0
            
        x = self.vectorize_trace(trace)

        # Ensure we have the right dimensions
        if x.dim() == 1:
            x = x.unsqueeze(0)
        
        try:
            z, recon = self.model(x)
            loss = self.loss_fn(recon, x)

            self.optimizer.zero_grad()
            loss.backward()
            self.optimizer.step()

            return z.detach(), loss.item()
        except Exception as e:
            self.logger.error(f"Training step failed: {e}")
            # Return zeros and a high loss if training fails
            return torch.zeros((x.size(0), self.model.encoder[-1].out_features)), 1.0

    def encode_trace(self, trace: List[Dict[str, Any]]) -> torch.Tensor:
        """
        Encode a trace to its latent representation without training.
        
        Args:
            trace: Execution trace to encode
            
        Returns:
            Latent representation tensor
        """
        if not trace:
            return torch.zeros((1, 32))
        
        x = self.vectorize_trace(trace)
        if x.dim() == 1:
            x = x.unsqueeze(0)
        
        with torch.no_grad():
            z, _ = self.model(x)
            return z


def create_deg_trainer() -> DEGTrainer:
    """Factory function to create a DEG trainer."""
    return DEGTrainer()


# Example usage
if __name__ == "__main__":
    # Create a sample trace
    sample_trace = [
        {"t": 0, "event_type": "node_entry", "node_id": "A", "value": 5.0},
        {"t": 1, "event_type": "variable_write", "variable_name": "x", "value": 10.0},
        {"t": 2, "event_type": "node_entry", "node_id": "B", "value": 15.0},
        {"t": 3, "event_type": "function_call", "function_name": "add", "result": 25.0},
        {"t": 4, "event_type": "function_return", "output": 25.0}
    ]
    
    # Create trainer and run a training step
    trainer = DEGTrainer()
    z, loss = trainer.train_step(sample_trace)
    
    print(f"Latent embedding shape: {z.shape}")
    print(f"Reconstruction loss: {loss:.4f}")
    
    # Test encoding
    encoded = trainer.encode_trace(sample_trace)
    print(f"Encoded shape: {encoded.shape}")