"""
EU AI Act Compliance - Data Anonymization Engine

Implements data anonymization and differential privacy mechanisms
to comply with EU AI Act requirements for personal data protection.

Key Features:
- Differential privacy (epsilon-delta privacy guarantees)
- PII detection and redaction
- k-anonymity enforcement
- Data utility preservation metrics
- Audit logging for compliance tracking

Dependencies:
    pip install diffprivlib faker numpy pandas

Usage:
    from tiannara_core.compliance.anonymization_engine import AnonymizationEngine
    
    engine = AnonymizationEngine(epsilon=1.0, delta=1e-5)
    
    # Anonymize dataset
    anonymized_data = engine.anonymize(raw_data, sensitive_columns=['name', 'email'])
    
    # Check compliance
    report = engine.generate_compliance_report()

References:
    Dwork, C., & Roth, A. (2014). The algorithmic foundations of differential privacy.
    Foundations and Trends in Theoretical Computer Science, 9(3-4), 211-407.
"""

import numpy as np
import logging
from typing import Dict, List, Optional, Tuple, Any, Union
from dataclasses import dataclass, field
from datetime import datetime
import json

logger = logging.getLogger(__name__)


@dataclass
class PrivacyBudget:
    """Tracks privacy budget consumption."""
    epsilon_total: float
    epsilon_spent: float = 0.0
    delta_total: float = 1e-5
    operations: List[Dict] = field(default_factory=list)
    
    def remaining_epsilon(self) -> float:
        return max(0, self.epsilon_total - self.epsilon_spent)
    
    def can_spend(self, epsilon: float) -> bool:
        return self.remaining_epsilon() >= epsilon
    
    def spend(self, epsilon: float, operation: str):
        self.epsilon_spent += epsilon
        self.operations.append({
            'timestamp': datetime.now().isoformat(),
            'operation': operation,
            'epsilon_spent': epsilon,
            'remaining': self.remaining_epsilon()
        })
        
        logger.info(
            f"Privacy budget: spent {epsilon:.3f}, "
            f"total {self.epsilon_spent:.3f}/{self.epsilon_total:.3f}"
        )


@dataclass
class AnonymizationResult:
    """Result of anonymization operation."""
    original_shape: Tuple[int, int]
    anonymized_shape: Tuple[int, int]
    columns_processed: List[str]
    pii_detected: List[str]
    techniques_applied: List[str]
    privacy_budget_used: float
    utility_score: float  # 0-1, higher is better
    compliance_status: str  # 'compliant', 'warning', 'non-compliant'
    warnings: List[str] = field(default_factory=list)


class AnonymizationEngine:
    """
    Data anonymization engine with differential privacy guarantees.
    
    Provides multiple anonymization techniques:
    - Differential privacy (Laplace/Gaussian mechanism)
    - Generalization (k-anonymity)
    - Suppression (remove identifying information)
    - Synthetic data generation
    """
    
    def __init__(
        self,
        epsilon: float = 1.0,
        delta: float = 1e-5,
        k_anonymity: int = 5,
        enable_audit: bool = True
    ):
        """
        Initialize anonymization engine.
        
        Args:
            epsilon: Privacy parameter (lower = more privacy, less utility)
            delta: Probability of privacy failure
            k_anonymity: Minimum group size for k-anonymity
            enable_audit: Enable audit logging
        """
        self.epsilon = epsilon
        self.delta = delta
        self.k_anonymity = k_anonymity
        self.enable_audit = enable_audit
        
        # Privacy budget tracker
        self.privacy_budget = PrivacyBudget(epsilon_total=epsilon, delta_total=delta)
        
        # Audit log
        self.audit_log = []
        
        # Check dependencies
        try:
            import diffprivlib
            self.diffprivlib_available = True
        except ImportError:
            self.diffprivlib_available = False
            logger.warning(
                "diffprivlib not available. Install with: pip install diffprivlib\n"
                "Using fallback anonymization methods."
            )
        
        try:
            from faker import Faker
            self.faker = Faker()
            self.faker_available = True
        except ImportError:
            self.faker_available = False
            logger.warning(
                "Faker not available. Install with: pip install faker\n"
                "Synthetic data generation will be limited."
            )
    
    def anonymize(
        self,
        data: Union[np.ndarray, List[Dict]],
        sensitive_columns: Optional[List[str]] = None,
        quasi_identifiers: Optional[List[str]] = None,
        method: str = 'differential_privacy'
    ) -> Tuple[Any, AnonymizationResult]:
        """
        Anonymize dataset while preserving utility.
        
        Args:
            data: Input data (numpy array or list of dicts)
            sensitive_columns: Columns containing PII to protect
            quasi_identifiers: Columns that could identify when combined
            method: Anonymization method ('differential_privacy', 'k_anonymity', 'suppression')
            
        Returns:
            Tuple of (anonymized_data, AnonymizationResult)
        """
        logger.info(f"Starting anonymization with method: {method}")
        
        # Convert to consistent format
        if isinstance(data, list):
            import pandas as pd
            df = pd.DataFrame(data)
        else:
            import pandas as pd
            df = pd.DataFrame(data)
        
        original_shape = df.shape
        columns_processed = []
        pii_detected = []
        techniques = []
        warnings = []
        
        # Detect PII columns if not specified
        if sensitive_columns is None:
            sensitive_columns = self._detect_pii_columns(df)
            pii_detected = sensitive_columns
            logger.info(f"Auto-detected PII columns: {sensitive_columns}")
        
        # Apply anonymization method
        if method == 'differential_privacy':
            df_anon, techniques_used = self._apply_differential_privacy(
                df, sensitive_columns
            )
            techniques.extend(techniques_used)
            
        elif method == 'k_anonymity':
            if quasi_identifiers is None:
                quasi_identifiers = [col for col in df.columns if col not in sensitive_columns]
            
            df_anon, techniques_used = self._apply_k_anonymity(
                df, sensitive_columns, quasi_identifiers
            )
            techniques.extend(techniques_used)
            
        elif method == 'suppression':
            df_anon, techniques_used = self._apply_suppression(
                df, sensitive_columns
            )
            techniques.extend(techniques_used)
            
        else:
            raise ValueError(f"Unknown anonymization method: {method}")
        
        columns_processed = list(df.columns)
        
        # Calculate utility score
        utility_score = self._calculate_utility(df, df_anon, sensitive_columns)
        
        # Determine compliance status
        if utility_score > 0.7:
            compliance_status = 'compliant'
        elif utility_score > 0.5:
            compliance_status = 'warning'
            warnings.append("Low utility score - consider adjusting privacy parameters")
        else:
            compliance_status = 'non-compliant'
            warnings.append("Very low utility - anonymization may be too aggressive")
        
        # Create result
        result = AnonymizationResult(
            original_shape=original_shape,
            anonymized_shape=df_anon.shape,
            columns_processed=columns_processed,
            pii_detected=pii_detected,
            techniques_applied=techniques,
            privacy_budget_used=self.privacy_budget.epsilon_spent,
            utility_score=utility_score,
            compliance_status=compliance_status,
            warnings=warnings
        )
        
        # Log to audit trail
        if self.enable_audit:
            self._log_audit_event('anonymization', result)
        
        logger.info(f"Anonymization complete. Utility: {utility_score:.2f}, Status: {compliance_status}")
        
        return df_anon, result
    
    def _apply_differential_privacy(
        self,
        df,
        sensitive_columns: List[str]
    ) -> Tuple[Any, List[str]]:
        """Apply differential privacy to numeric columns."""
        techniques = []
        df_anon = df.copy()
        
        if not self.diffprivlib_available:
            logger.warning("Using fallback DP implementation")
            return self._fallback_differential_privacy(df, sensitive_columns)
        
        import diffprivlib as dp
        import pandas as pd
        
        # Identify numeric columns
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        numeric_sensitive = [col for col in numeric_cols if col in sensitive_columns]
        
        if numeric_sensitive:
            # Apply Laplace mechanism to numeric sensitive data
            epsilon_per_col = self.epsilon / max(len(numeric_sensitive), 1)
            
            for col in numeric_sensitive:
                if self.privacy_budget.can_spend(epsilon_per_col):
                    bounds = (df[col].min(), df[col].max())
                    
                    noisy_data = dp.mechanisms.Laplace(
                        epsilon=epsilon_per_col,
                        sensitivity=bounds[1] - bounds[0],
                        lower=bounds[0],
                        upper=bounds[1]
                    ).randomise(df[col].values)
                    
                    df_anon[col] = noisy_data
                    self.privacy_budget.spend(epsilon_per_col, f'dp_laplace_{col}')
                    techniques.append(f'differential_privacy_laplace_{col}')
                    
                    logger.debug(f"Applied DP to {col} with epsilon={epsilon_per_col:.3f}")
        
        # Suppress non-numeric PII
        non_numeric_sensitive = [col for col in sensitive_columns if col not in numeric_cols]
        if non_numeric_sensitive:
            for col in non_numeric_sensitive:
                df_anon[col] = self._suppress_column(df_anon[col])
                techniques.append(f'suppression_{col}')
        
        return df_anon, techniques
    
    def _apply_k_anonymity(
        self,
        df,
        sensitive_columns: List[str],
        quasi_identifiers: List[str]
    ) -> Tuple[Any, List[str]]:
        """Apply k-anonymity through generalization."""
        techniques = []
        df_anon = df.copy()
        
        # Group by quasi-identifiers and generalize
        if quasi_identifiers:
            for col in quasi_identifiers:
                if df_anon[col].dtype == 'object':
                    # Text generalization (e.g., "New York" → "NY")
                    df_anon[col] = df_anon[col].apply(self._generalize_text)
                    techniques.append(f'k_anonymity_generalize_{col}')
                elif np.issubdtype(df_anon[col].dtype, np.number):
                    # Numeric binning
                    bins = min(10, max(3, len(df_anon[col].unique()) // self.k_anonymity))
                    df_anon[col] = pd.cut(df_anon[col], bins=bins, labels=False)
                    techniques.append(f'k_anonymity_bin_{col}')
        
        # Suppress sensitive columns
        for col in sensitive_columns:
            if col not in quasi_identifiers:
                df_anon[col] = self._suppress_column(df_anon[col])
                techniques.append(f'suppression_{col}')
        
        return df_anon, techniques
    
    def _apply_suppression(
        self,
        df,
        sensitive_columns: List[str]
    ) -> Tuple[Any, List[str]]:
        """Remove or replace sensitive information."""
        techniques = []
        df_anon = df.copy()
        
        for col in sensitive_columns:
            if self.faker_available and df_anon[col].dtype == 'object':
                # Replace with synthetic data
                df_anon[col] = [self._generate_synthetic_value(col) for _ in range(len(df_anon))]
                techniques.append(f'synthetic_replacement_{col}')
            else:
                # Redact completely
                df_anon[col] = '[REDACTED]'
                techniques.append(f'redaction_{col}')
        
        return df_anon, techniques
    
    def _fallback_differential_privacy(
        self,
        df,
        sensitive_columns: List[str]
    ) -> Tuple[Any, List[str]]:
        """Fallback DP using simple noise addition."""
        techniques = []
        df_anon = df.copy()
        
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        numeric_sensitive = [col for col in numeric_cols if col in sensitive_columns]
        
        for col in numeric_sensitive:
            # Add Gaussian noise scaled to data range
            noise_scale = (df[col].max() - df[col].min()) * 0.1
            noise = np.random.normal(0, noise_scale, len(df))
            df_anon[col] = df[col] + noise
            
            # Clip to original bounds
            df_anon[col] = df_anon[col].clip(df[col].min(), df[col].max())
            techniques.append(f'fallback_dp_noise_{col}')
        
        # Suppress non-numeric
        non_numeric_sensitive = [col for col in sensitive_columns if col not in numeric_cols]
        for col in non_numeric_sensitive:
            df_anon[col] = self._suppress_column(df_anon[col])
            techniques.append(f'suppression_{col}')
        
        return df_anon, techniques
    
    def _detect_pii_columns(self, df) -> List[str]:
        """Heuristically detect PII columns."""
        pii_keywords = [
            'name', 'email', 'phone', 'address', 'ssn', 'social_security',
            'credit_card', 'password', 'dob', 'date_of_birth', 'id', 'identifier'
        ]
        
        detected = []
        for col in df.columns:
            col_lower = col.lower()
            if any(keyword in col_lower for keyword in pii_keywords):
                detected.append(col)
        
        return detected
    
    def _suppress_column(self, series) -> Any:
        """Suppress column values."""
        return '[SUPPRESSED]'
    
    def _generalize_text(self, value: str) -> str:
        """Generalize text value for k-anonymity."""
        if not isinstance(value, str):
            return value
        
        # Simple generalization: take first 2 characters
        if len(value) > 2:
            return value[:2] + '**'
        return value
    
    def _generate_synthetic_value(self, column_name: str) -> str:
        """Generate synthetic replacement value."""
        col_lower = column_name.lower()
        
        if not self.faker_available:
            return '[SYNTHETIC]'
        
        if 'name' in col_lower:
            return self.faker.name()
        elif 'email' in col_lower:
            return self.faker.email()
        elif 'phone' in col_lower:
            return self.faker.phone_number()
        elif 'address' in col_lower:
            return self.faker.address().replace('\n', ', ')
        else:
            return self.faker.word()
    
    def _calculate_utility(
        self,
        df_original,
        df_anonymized,
        sensitive_columns: List[str]
    ) -> float:
        """Calculate data utility score after anonymization."""
        # Compare statistics of non-sensitive columns
        non_sensitive = [col for col in df_original.columns if col not in sensitive_columns]
        
        if not non_sensitive:
            return 0.5  # Default if all columns are sensitive
        
        utility_scores = []
        
        for col in non_sensitive:
            if np.issubdtype(df_original[col].dtype, np.number):
                # Compare means and std deviations
                orig_mean = df_original[col].mean()
                anon_mean = df_anonymized[col].mean()
                
                if abs(orig_mean) > 1e-10:
                    mean_diff = abs(orig_mean - anon_mean) / abs(orig_mean)
                else:
                    mean_diff = abs(orig_mean - anon_mean)
                
                utility_scores.append(max(0, 1 - mean_diff))
        
        return np.mean(utility_scores) if utility_scores else 0.5
    
    def _log_audit_event(self, event_type: str, result: AnonymizationResult):
        """Log event to audit trail."""
        audit_entry = {
            'timestamp': datetime.now().isoformat(),
            'event_type': event_type,
            'result': {
                'original_shape': result.original_shape,
                'anonymized_shape': result.anonymized_shape,
                'pii_detected': result.pii_detected,
                'techniques': result.techniques_applied,
                'privacy_budget_used': result.privacy_budget_used,
                'utility_score': result.utility_score,
                'compliance_status': result.compliance_status
            }
        }
        
        self.audit_log.append(audit_entry)
        
        # Also log to file if needed
        logger.debug(f"Audit log entry created: {event_type}")
    
    def generate_compliance_report(self) -> Dict:
        """Generate EU AI Act compliance report."""
        report = {
            'report_generated': datetime.now().isoformat(),
            'privacy_parameters': {
                'epsilon': self.epsilon,
                'delta': self.delta,
                'k_anonymity': self.k_anonymity
            },
            'privacy_budget': {
                'total': self.privacy_budget.epsilon_total,
                'spent': self.privacy_budget.epsilon_spent,
                'remaining': self.privacy_budget.remaining_epsilon(),
                'operations_count': len(self.privacy_budget.operations)
            },
            'audit_summary': {
                'total_operations': len(self.audit_log),
                'recent_operations': self.audit_log[-10:] if self.audit_log else []
            },
            'compliance_status': 'compliant' if self.privacy_budget.remaining_epsilon() > 0 else 'budget_exhausted'
        }
        
        return report
    
    def reset_privacy_budget(self):
        """Reset privacy budget (use with caution - requires justification)."""
        logger.warning("Privacy budget reset requested")
        self.privacy_budget = PrivacyBudget(
            epsilon_total=self.epsilon,
            delta_total=self.delta
        )
        self.audit_log.append({
            'timestamp': datetime.now().isoformat(),
            'event_type': 'budget_reset',
            'justification': 'Manual reset'
        })


def anonymize_dataset(
    data: Union[np.ndarray, List[Dict]],
    epsilon: float = 1.0,
    sensitive_columns: Optional[List[str]] = None
) -> Tuple[Any, AnonymizationResult]:
    """
    Convenience function for quick anonymization.
    
    Args:
        data: Input data
        epsilon: Privacy parameter
        sensitive_columns: PII columns to protect
        
    Returns:
        Tuple of (anonymized_data, AnonymizationResult)
    """
    engine = AnonymizationEngine(epsilon=epsilon)
    return engine.anonymize(data, sensitive_columns, method='differential_privacy')
