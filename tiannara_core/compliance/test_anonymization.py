"""
Anonymization Engine Test Script

Demonstrates EU AI Act compliance through data anonymization
with differential privacy guarantees.

Usage:
    python tiannara_core/compliance/test_anonymization.py
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.compliance.anonymization_engine import (
        AnonymizationEngine,
        anonymize_dataset
    )
    ANONYMIZATION_AVAILABLE = True
except ImportError as e:
    print(f"⚠️  Anonymization module not available: {e}")
    ANONYMIZATION_AVAILABLE = False


def generate_sample_personal_data(n_records=100):
    """Generate synthetic personal data for testing."""
    import pandas as pd
    
    np.random.seed(42)
    
    data = {
        'user_id': range(1, n_records + 1),
        'name': [f'User_{i}' for i in range(1, n_records + 1)],
        'email': [f'user{i}@example.com' for i in range(1, n_records + 1)],
        'age': np.random.randint(18, 80, n_records),
        'income': np.random.normal(50000, 15000, n_records).astype(int),
        'city': np.random.choice(['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'], n_records),
        'purchase_amount': np.random.exponential(100, n_records).round(2),
        'phone': [f'555-{np.random.randint(1000, 9999)}' for _ in range(n_records)]
    }
    
    return pd.DataFrame(data)


def test_differential_privacy():
    """Test differential privacy anonymization."""
    print("=" * 80)
    print("EU AI Act Compliance - Differential Privacy Test")
    print("=" * 80)
    
    # Generate sample data
    print("\n1. Generating sample personal data...")
    df = generate_sample_personal_data(n_records=100)
    print(f"   Original data shape: {df.shape}")
    print(f"   Columns: {list(df.columns)}")
    print(f"\n   Sample records:")
    print(df.head(3).to_string(index=False))
    
    # Apply differential privacy
    print("\n2. Applying differential privacy anonymization...")
    engine = AnonymizationEngine(epsilon=1.0, delta=1e-5)
    
    sensitive_cols = ['name', 'email', 'phone', 'income']
    df_anon, result = engine.anonymize(
        df,
        sensitive_columns=sensitive_cols,
        method='differential_privacy'
    )
    
    print(f"\n3. Anonymization Results:")
    print("-" * 80)
    print(f"   Original shape: {result.original_shape}")
    print(f"   Anonymized shape: {result.anonymized_shape}")
    print(f"   PII detected: {result.pii_detected}")
    print(f"   Techniques applied: {len(result.techniques_applied)}")
    for tech in result.techniques_applied[:5]:
        print(f"      - {tech}")
    print(f"   Utility score: {result.utility_score:.2f}/1.00")
    print(f"   Compliance status: {result.compliance_status}")
    
    if result.warnings:
        print(f"\n   Warnings:")
        for warning in result.warnings:
            print(f"      ⚠️  {warning}")
    
    print(f"\n4. Anonymized Data Sample:")
    print("-" * 80)
    print(df_anon.head(3).to_string(index=False))
    
    # Check privacy budget
    print(f"\n5. Privacy Budget Status:")
    print("-" * 80)
    report = engine.generate_compliance_report()
    print(f"   Total epsilon: {report['privacy_budget']['total']}")
    print(f"   Spent: {report['privacy_budget']['spent']:.3f}")
    print(f"   Remaining: {report['privacy_budget']['remaining']:.3f}")
    print(f"   Operations: {report['privacy_budget']['operations_count']}")
    
    print("\n" + "=" * 80)
    print("Differential Privacy Test Completed!")
    print("=" * 80)


def test_k_anonymity():
    """Test k-anonymity anonymization."""
    print("\n" + "=" * 80)
    print("K-Anonymity Test")
    print("=" * 80)
    
    # Generate sample data
    df = generate_sample_personal_data(n_records=100)
    
    print("\n1. Applying k-anonymity (k=5)...")
    engine = AnonymizationEngine(epsilon=1.0, k_anonymity=5)
    
    sensitive_cols = ['name', 'email', 'phone']
    quasi_identifiers = ['age', 'city', 'income']
    
    df_anon, result = engine.anonymize(
        df,
        sensitive_columns=sensitive_cols,
        quasi_identifiers=quasi_identifiers,
        method='k_anonymity'
    )
    
    print(f"\n2. K-Anonymity Results:")
    print("-" * 80)
    print(f"   Utility score: {result.utility_score:.2f}")
    print(f"   Compliance status: {result.compliance_status}")
    print(f"   Techniques: {', '.join(result.techniques_applied[:3])}")
    
    print(f"\n3. Anonymized Sample:")
    print(df_anon.head(3).to_string(index=False))
    
    print("\nK-Anonymity Test Completed!")


def test_suppression():
    """Test suppression-based anonymization."""
    print("\n" + "=" * 80)
    print("Suppression/Redaction Test")
    print("=" * 80)
    
    df = generate_sample_personal_data(n_records=50)
    
    print("\n1. Applying complete suppression...")
    engine = AnonymizationEngine(epsilon=1.0)
    
    sensitive_cols = ['name', 'email', 'phone']
    df_anon, result = engine.anonymize(
        df,
        sensitive_columns=sensitive_cols,
        method='suppression'
    )
    
    print(f"\n2. Suppression Results:")
    print("-" * 80)
    print(f"   Utility score: {result.utility_score:.2f}")
    print(f"   Techniques: {result.techniques_applied}")
    
    print(f"\n3. Redacted Sample:")
    print(df_anon.head(3).to_string(index=False))
    
    print("\nSuppression Test Completed!")


def test_convenience_function():
    """Test convenience function for quick anonymization."""
    print("\n" + "=" * 80)
    print("Convenience Function Test")
    print("=" * 80)
    
    df = generate_sample_personal_data(n_records=50)
    
    print("\nRunning anonymize_dataset()...")
    df_anon, result = anonymize_dataset(
        df,
        epsilon=0.5,
        sensitive_columns=['name', 'email']
    )
    
    print(f"\nResult:")
    print(f"   Utility: {result.utility_score:.2f}")
    print(f"   Status: {result.compliance_status}")
    print(f"   PII detected: {result.pii_detected}")
    
    print("\nConvenience function test passed!")


def test_multiple_operations():
    """Test privacy budget tracking across multiple operations."""
    print("\n" + "=" * 80)
    print("Privacy Budget Tracking Test")
    print("=" * 80)
    
    engine = AnonymizationEngine(epsilon=2.0)
    
    print("\nPerforming multiple anonymization operations...")
    
    for i in range(3):
        df = generate_sample_personal_data(n_records=50)
        df_anon, result = engine.anonymize(
            df,
            sensitive_columns=['name', 'email', 'income'],
            method='differential_privacy'
        )
        
        print(f"\nOperation {i+1}:")
        print(f"   Utility: {result.utility_score:.2f}")
        print(f"   Budget used: {result.privacy_budget_used:.3f}")
    
    print(f"\nFinal Privacy Budget:")
    report = engine.generate_compliance_report()
    print(f"   Total: {report['privacy_budget']['total']}")
    print(f"   Spent: {report['privacy_budget']['spent']:.3f}")
    print(f"   Remaining: {report['privacy_budget']['remaining']:.3f}")
    print(f"   Status: {report['compliance_status']}")
    
    print("\nPrivacy budget tracking test completed!")


if __name__ == "__main__":
    if not ANONYMIZATION_AVAILABLE:
        print("⚠️  Cannot run tests - Anonymization module not available")
        print("Install dependencies: pip install diffprivlib faker pandas numpy")
        sys.exit(1)
    
    try:
        test_differential_privacy()
        test_k_anonymity()
        test_suppression()
        test_convenience_function()
        test_multiple_operations()
        
        print("\n" + "=" * 80)
        print("✅ ALL TESTS PASSED!")
        print("=" * 80)
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
