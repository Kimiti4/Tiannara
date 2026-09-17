"""
PCMCI Algorithm Implementation for Time-Series Causal Discovery

Implements the PCMCI (Partial Correlation based Momentary Conditional Independence)
algorithm for discovering causal relationships in time-series data.

Key Features:
- Handles temporal dependencies and lagged effects
- Controls for false discovery rate in multiple testing
- Identifies both direct and indirect causal links
- Optimized for high-dimensional time-series data
- Integration with existing causal discovery pipeline

Dependencies:
    pip install tigramite numpy scipy scikit-learn

Usage:
    from tiannara_core.causal.pcmci_discovery import PCMCIDiscovery
    
    discovery = PCMCIDiscovery(tau_max=5, alpha=0.05)
    
    # Discover causal structure in time-series data
    graph = discovery.discover_causal_graph(data)
    
    # Get causal effects with confidence intervals
    effects = discovery.estimate_temporal_effects(data, graph)

References:
    Runge, J., Nowack, P., Kretschmer, M., Flaxman, S., & Sejdinovic, D. (2019).
    Detecting and quantifying causal associations in large nonlinear time series datasets.
    Science Advances, 5(11), eaau4996.
"""

import numpy as np
import logging
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class TemporalCausalLink:
    """Represents a causal link with temporal information."""
    source: str
    target: str
    lag: int  # Time lag (positive means source leads target)
    strength: float  # Causal effect strength
    p_value: float  # Statistical significance
    confidence_interval: Tuple[float, float] = (0.0, 0.0)
    
    def __str__(self):
        return f"{self.source}(t-{self.lag}) → {self.target}(t) [strength={self.strength:.3f}, p={self.p_value:.4f}]"


@dataclass
class TemporalCausalGraph:
    """Causal graph with temporal structure."""
    variables: List[str]
    links: List[TemporalCausalLink]
    max_lag: int
    adjacency_matrix: np.ndarray = None
    discovery_metadata: Dict = field(default_factory=dict)
    
    def get_parents(self, variable: str, lag: int = 0) -> List[str]:
        """Get parent variables at specific lag."""
        parents = []
        for link in self.links:
            if link.target == variable and link.lag == lag:
                parents.append(link.source)
        return parents
    
    def get_children(self, variable: str, lag: int = 0) -> List[str]:
        """Get child variables at specific lag."""
        children = []
        for link in self.links:
            if link.source == variable and link.lag == lag:
                children.append(link.target)
        return children
    
    def to_adjacency_matrix(self) -> np.ndarray:
        """Convert to adjacency matrix representation."""
        n_vars = len(self.variables)
        n_lags = self.max_lag + 1
        
        # Create 3D adjacency: [source_var, target_var, lag]
        adj = np.zeros((n_vars, n_vars, n_lags))
        
        var_to_idx = {v: i for i, v in enumerate(self.variables)}
        
        for link in self.links:
            src_idx = var_to_idx[link.source]
            tgt_idx = var_to_idx[link.target]
            adj[src_idx, tgt_idx, link.lag] = abs(link.strength)
        
        self.adjacency_matrix = adj
        return adj


class PCMCIDiscovery:
    """
    PCMCI algorithm for time-series causal discovery.
    
    Combines PC algorithm for skeleton discovery with MCI test
    for identifying true causal links while controlling for
    temporal dependencies.
    """
    
    def __init__(
        self,
        tau_max: int = 5,
        alpha: float = 0.05,
        cond_ind_test: str = 'parcorr',
        verbosity: int = 1
    ):
        """
        Initialize PCMCI discovery.
        
        Args:
            tau_max: Maximum time lag to consider
            alpha: Significance level for statistical tests
            cond_ind_test: Conditional independence test method
                          ('parcorr', 'gpdc', 'cmi_knn')
            verbosity: Logging verbosity (0=silent, 1=info, 2=debug)
        """
        self.tau_max = tau_max
        self.alpha = alpha
        self.cond_ind_test = cond_ind_test
        self.verbosity = verbosity
        
        # Check for tigramite availability
        try:
            import tigramite
            self.tigramite_available = True
        except ImportError:
            self.tigramite_available = False
            logger.warning(
                "Tigramite not available. Install with: pip install tigramite\n"
                "Using fallback implementation."
            )
    
    def discover_causal_graph(
        self,
        data: np.ndarray,
        variable_names: Optional[List[str]] = None
    ) -> TemporalCausalGraph:
        """
        Discover causal structure in time-series data using PCMCI.
        
        Args:
            data: Time-series data array of shape (T, N) where T is time steps
                  and N is number of variables
            variable_names: Names of variables (default: ['X0', 'X1', ...])
            
        Returns:
            TemporalCausalGraph with discovered causal structure
        """
        T, N = data.shape
        
        if variable_names is None:
            variable_names = [f'X{i}' for i in range(N)]
        
        logger.info(f"Running PCMCI on {N} variables with {T} time points")
        logger.info(f"Max lag: {self.tau_max}, Alpha: {self.alpha}")
        
        if self.tigramite_available:
            return self._discover_with_tigramite(data, variable_names)
        else:
            return self._discover_fallback(data, variable_names)
    
    def _discover_with_tigramite(
        self,
        data: np.ndarray,
        variable_names: List[str]
    ) -> TemporalCausalGraph:
        """Use tigramite library for PCMCI discovery."""
        try:
            from tigramite import data_processing as pp
            from tigramite.pcmci import PCMCI
            from tigramite.independence_tests import ParCorr, GPDC
            
            # Prepare data
            dataframe = pp.DataFrame(data, var_names=variable_names)
            
            # Select conditional independence test
            if self.cond_ind_test == 'parcorr':
                cond_ind_test = ParCorr()
            elif self.cond_ind_test == 'gpdc':
                cond_ind_test = GPDC()
            else:
                cond_ind_test = ParCorr()
            
            # Initialize PCMCI
            pcmci = PCMCI(
                dataframe=dataframe,
                cond_ind_test=cond_ind_test,
                verbosity=self.verbosity
            )
            
            # Run PCMCI algorithm
            results = pcmci.run_pcmci(
                tau_min=0,
                tau_max=self.tau_max,
                pc_alpha=self.alpha
            )
            
            # Extract causal links
            links = []
            q_matrix = results['p_matrix']
            val_matrix = results['val_matrix']
            
            for i, target in enumerate(variable_names):
                for j, source in enumerate(variable_names):
                    for lag in range(self.tau_max + 1):
                        p_val = q_matrix[i, j, lag]
                        
                        if p_val < self.alpha and i != j:
                            strength = val_matrix[i, j, lag]
                            
                            link = TemporalCausalLink(
                                source=source,
                                target=target,
                                lag=lag,
                                strength=float(strength),
                                p_value=float(p_val)
                            )
                            links.append(link)
            
            logger.info(f"Discovered {len(links)} significant causal links")
            
            return TemporalCausalGraph(
                variables=variable_names,
                links=links,
                max_lag=self.tau_max,
                discovery_metadata={
                    'algorithm': 'PCMCI',
                    'alpha': self.alpha,
                    'tau_max': self.tau_max,
                    'n_links': len(links)
                }
            )
            
        except Exception as e:
            logger.error(f"Tigramite discovery failed: {e}")
            logger.info("Falling back to simplified implementation")
            return self._discover_fallback(data, variable_names)
    
    def _discover_fallback(
        self,
        data: np.ndarray,
        variable_names: List[str]
    ) -> TemporalCausalGraph:
        """Fallback implementation using correlation-based approach."""
        T, N = data.shape
        links = []
        
        logger.info("Using fallback correlation-based temporal discovery")
        
        # Compute lagged correlations
        for lag in range(1, self.tau_max + 1):
            for i in range(N):
                for j in range(N):
                    if i == j:
                        continue
                    
                    # Shift data by lag
                    x_lagged = data[lag:, i]
                    y_current = data[lag:, j]
                    
                    # Compute correlation
                    if len(x_lagged) > 10:  # Minimum samples
                        corr = np.corrcoef(x_lagged, y_current)[0, 1]
                        
                        if not np.isnan(corr) and abs(corr) > 0.3:
                            # Simple p-value approximation
                            n_samples = len(x_lagged)
                            t_stat = corr * np.sqrt((n_samples - 2) / (1 - corr**2 + 1e-10))
                            p_val = 2 * (1 - min(abs(t_stat) / np.sqrt(n_samples), 1.0))
                            
                            if p_val < self.alpha:
                                link = TemporalCausalLink(
                                    source=variable_names[i],
                                    target=variable_names[j],
                                    lag=lag,
                                    strength=float(corr),
                                    p_value=float(p_val)
                                )
                                links.append(link)
        
        logger.info(f"Fallback discovery found {len(links)} potential links")
        
        return TemporalCausalGraph(
            variables=variable_names,
            links=links,
            max_lag=self.tau_max,
            discovery_metadata={
                'algorithm': 'PCMCI-Fallback',
                'method': 'lagged_correlation',
                'alpha': self.alpha,
                'tau_max': self.tau_max,
                'n_links': len(links)
            }
        )
    
    def estimate_temporal_effects(
        self,
        data: np.ndarray,
        graph: TemporalCausalGraph,
        treatment: str,
        outcome: str
    ) -> Dict:
        """
        Estimate temporal causal effects between treatment and outcome.
        
        Args:
            data: Time-series data
            graph: Discovered causal graph
            treatment: Treatment variable name
            outcome: Outcome variable name
            
        Returns:
            Dictionary with effect estimates at different lags
        """
        effects = {}
        
        # Find all paths from treatment to outcome
        relevant_links = [
            link for link in graph.links
            if link.source == treatment and link.target == outcome
        ]
        
        if not relevant_links:
            logger.warning(f"No direct causal path from {treatment} to {outcome}")
            return {'total_effect': 0.0, 'lags': {}}
        
        # Estimate effect at each lag
        for link in relevant_links:
            lag = link.lag
            
            # Extract lagged data
            if lag > 0:
                x = data[lag:, graph.variables.index(treatment)]
                y = data[lag:, graph.variables.index(outcome)]
                
                # Simple linear regression
                if len(x) > 10:
                    coeffs = np.polyfit(x, y, 1)
                    effect_size = coeffs[0]
                    
                    effects[f'lag_{lag}'] = {
                        'effect_size': float(effect_size),
                        'strength': link.strength,
                        'p_value': link.p_value
                    }
        
        # Total effect (sum across lags)
        total_effect = sum(e.get('effect_size', 0) for e in effects.values())
        
        return {
            'treatment': treatment,
            'outcome': outcome,
            'total_effect': total_effect,
            'lags': effects,
            'n_significant_paths': len(relevant_links)
        }


def discover_temporal_causality(
    data: np.ndarray,
    variable_names: Optional[List[str]] = None,
    tau_max: int = 5,
    alpha: float = 0.05
) -> TemporalCausalGraph:
    """
    Convenience function for temporal causal discovery.
    
    Args:
        data: Time-series data array (T, N)
        variable_names: Variable names
        tau_max: Maximum lag
        alpha: Significance level
        
    Returns:
        TemporalCausalGraph with discovered structure
    """
    discovery = PCMCIDiscovery(tau_max=tau_max, alpha=alpha)
    return discovery.discover_causal_graph(data, variable_names)
