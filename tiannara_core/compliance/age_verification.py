"""
Age Verification & Geo-Blocking Compliance System

Purpose: Ensure legal compliance for prediction/betting services
Features:
- Age verification (18+/21+ depending on jurisdiction)
- Geo-blocking for restricted regions
- IP-based location detection
- Compliance logging

Date: May 8, 2026
Status: Implementation Phase
"""

import json
import os
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple
from pathlib import Path


class AgeVerificationSystem:
    """
    Handles age verification for betting/prediction services.
    
    Supports:
    - 18+ jurisdictions (most countries)
    - 21+ jurisdictions (some US states, etc.)
    - Date of birth validation
    - ID document verification (future enhancement)
    """
    
    def __init__(self, storage_path: str = "compliance_data"):
        self.storage_path = Path(storage_path)
        self.storage_path.mkdir(parents=True, exist_ok=True)
        
        # Age requirements by country/region
        self.age_requirements = {
            # 21+ jurisdictions
            "US": 21,  # Most US states for gambling
            "US-AL": 21,
            "US-AZ": 21,
            "US-CO": 21,
            "US-IL": 21,
            "US-IN": 21,
            "US-IA": 21,
            "US-LA": 21,
            "US-MD": 21,
            "US-MA": 21,
            "US-MI": 21,
            "US-NH": 21,
            "US-NJ": 21,
            "US-NY": 21,
            "US-PA": 21,
            "US-TN": 21,
            "US-VA": 21,
            "US-WV": 21,
            
            # 18+ jurisdictions (default for most countries)
            "UK": 18,
            "CA": 19,  # Varies by province (18-19)
            "AU": 18,
            "DE": 18,
            "FR": 18,
            "ES": 18,
            "IT": 18,
            "NL": 18,
            "SE": 18,
            "NO": 18,
            "DK": 18,
            "FI": 18,
            "IE": 18,
            "NZ": 18,
            "ZA": 18,
            "KE": 18,  # Kenya
            "NG": 18,  # Nigeria
            "GH": 18,  # Ghana
            "IN": 18,  # India (varies by state)
            "BR": 18,  # Brazil
            "MX": 18,  # Mexico
            "AR": 18,  # Argentina
            "CL": 18,  # Chile
            "JP": 20,  # Japan
            "KR": 19,  # South Korea
            "SG": 21,  # Singapore
            "MY": 21,  # Malaysia
            "TH": 20,  # Thailand
            "PH": 21,  # Philippines
        }
        
        # Default age requirement
        self.default_age = 18
        
    def get_age_requirement(self, country_code: str, region_code: str = None) -> int:
        """
        Get minimum age requirement for a jurisdiction.
        
        Args:
            country_code: ISO 3166-1 alpha-2 country code (e.g., "US", "UK")
            region_code: Optional region/state code (e.g., "US-NJ")
            
        Returns:
            Minimum age requirement (18, 19, 20, or 21)
        """
        # Check specific region first
        if region_code:
            key = f"{country_code}-{region_code}"
            if key in self.age_requirements:
                return self.age_requirements[key]
        
        # Fall back to country-level
        if country_code in self.age_requirements:
            return self.age_requirements[country_code]
        
        # Default to 18
        return self.default_age
    
    def verify_age(self, date_of_birth: str, country_code: str, region_code: str = None) -> Dict:
        """
        Verify user meets age requirement.
        
        Args:
            date_of_birth: User's date of birth (YYYY-MM-DD format)
            country_code: User's country
            region_code: Optional region/state
            
        Returns:
            Verification result with status and details
        """
        try:
            # Parse date of birth
            dob = datetime.strptime(date_of_birth, "%Y-%m-%d").date()
            today = datetime.now().date()
            
            # Calculate age
            age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
            
            # Get required age for jurisdiction
            required_age = self.get_age_requirement(country_code, region_code)
            
            # Check if user meets requirement
            is_verified = age >= required_age
            
            result = {
                "verified": is_verified,
                "age": age,
                "required_age": required_age,
                "country": country_code,
                "region": region_code,
                "timestamp": datetime.now().isoformat()
            }
            
            if is_verified:
                result["status"] = "approved"
                result["message"] = f"Age verified: {age} years old (minimum: {required_age})"
            else:
                result["status"] = "rejected"
                result["message"] = f"Age requirement not met: {age} years old (minimum: {required_age})"
                
            # Log verification attempt
            self._log_verification(result)
            
            return result
            
        except ValueError as e:
            return {
                "verified": False,
                "status": "error",
                "message": f"Invalid date format: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    def verify_age_from_year(self, birth_year: int, country_code: str, region_code: str = None) -> Dict:
        """
        Verify age from birth year only (less precise but simpler).
        
        Args:
            birth_year: User's birth year
            country_code: User's country
            region_code: Optional region/state
            
        Returns:
            Verification result
        """
        current_year = datetime.now().year
        age = current_year - birth_year
        
        required_age = self.get_age_requirement(country_code, region_code)
        is_verified = age >= required_age
        
        result = {
            "verified": is_verified,
            "age": age,
            "required_age": required_age,
            "country": country_code,
            "region": region_code,
            "timestamp": datetime.now().isoformat()
        }
        
        if is_verified:
            result["status"] = "approved"
            result["message"] = f"Age verified: {age}+ years old (minimum: {required_age})"
        else:
            result["status"] = "rejected"
            result["message"] = f"Age requirement not met: {age} years old (minimum: {required_age})"
        
        self._log_verification(result)
        return result
    
    def _log_verification(self, result: Dict):
        """Log verification attempt for compliance records."""
        log_file = self.storage_path / "age_verification_log.jsonl"
        
        log_entry = {
            "timestamp": result["timestamp"],
            "verified": result["verified"],
            "age": result.get("age"),
            "required_age": result.get("required_age"),
            "country": result.get("country"),
            "region": result.get("region"),
            "status": result["status"]
        }
        
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")
    
    def store_verification(self, user_id: str, verification_result: Dict):
        """Store verification result for a user (for session persistence)."""
        verification_file = self.storage_path / f"verification_{user_id}.json"
        
        data = {
            "user_id": user_id,
            "verification": verification_result,
            "verified_at": datetime.now().isoformat(),
            "expires_at": (datetime.now() + timedelta(days=365)).isoformat()  # Valid for 1 year
        }
        
        with open(verification_file, "w") as f:
            json.dump(data, f, indent=2)
    
    def check_stored_verification(self, user_id: str) -> Optional[Dict]:
        """Check if user has valid stored verification."""
        verification_file = self.storage_path / f"verification_{user_id}.json"
        
        if not verification_file.exists():
            return None
        
        with open(verification_file, "r") as f:
            data = json.load(f)
        
        # Check if expired
        expires_at = datetime.fromisoformat(data["expires_at"])
        if datetime.now() > expires_at:
            return None
        
        return data["verification"]


class GeoBlockingSystem:
    """
    Handles geo-blocking for restricted jurisdictions.
    
    Features:
    - Country-level blocking
    - Region/state-level blocking
    - IP-based location detection
    - Whitelist/blacklist management
    """
    
    def __init__(self, storage_path: str = "compliance_data"):
        self.storage_path = Path(storage_path)
        self.storage_path.mkdir(parents=True, exist_ok=True)
        
        # Restricted countries (where online betting/predictions are illegal)
        self.restricted_countries = {
            "AE": "United Arab Emirates",  # Gambling prohibited
            "SA": "Saudi Arabia",  # Gambling prohibited
            "QA": "Qatar",  # Gambling prohibited
            "KW": "Kuwait",  # Gambling prohibited
            "OM": "Oman",  # Gambling prohibited
            "YE": "Yemen",  # Gambling prohibited
            "IR": "Iran",  # Gambling prohibited
            "PK": "Pakistan",  # Gambling largely prohibited
            "BD": "Bangladesh",  # Gambling prohibited
            "ID": "Indonesia",  # Gambling prohibited
            "MY": "Malaysia",  # Gambling restricted (Muslims)
            "BN": "Brunei",  # Gambling prohibited
            "MV": "Maldives",  # Gambling prohibited
            "AF": "Afghanistan",  # Gambling prohibited
            "KP": "North Korea",  # All gambling prohibited
            "CU": "Cuba",  # Gambling restricted
            "SY": "Syria",  # Gambling prohibited
        }
        
        # Restricted US states (where online sports betting is illegal)
        self.restricted_us_states = {
            "HI": "Hawaii",
            "UT": "Utah",
            "AK": "Alaska",  # Very limited
            "TX": "Texas",  # Currently illegal (changing)
            "CA": "California",  # Currently illegal (proposed)
            "GA": "Georgia",  # Currently illegal
            "SC": "South Carolina",  # Currently illegal
            "OK": "Oklahoma",  # Limited
            "WI": "Wisconsin",  # Very limited
        }
        
        # Whitelisted countries (always allowed)
        self.whitelisted_countries = set()
        
        # Load custom restrictions
        self._load_custom_restrictions()
    
    def is_country_restricted(self, country_code: str) -> Tuple[bool, str]:
        """
        Check if a country is restricted.
        
        Args:
            country_code: ISO 3166-1 alpha-2 country code
            
        Returns:
            Tuple of (is_restricted, reason)
        """
        # Check whitelist first
        if country_code in self.whitelisted_countries:
            return False, "Whitelisted country"
        
        # Check restricted list
        if country_code in self.restricted_countries:
            country_name = self.restricted_countries[country_code]
            return True, f"Gambling/predictions prohibited in {country_name}"
        
        return False, "Country allowed"
    
    def is_region_restricted(self, country_code: str, region_code: str = None) -> Tuple[bool, str]:
        """
        Check if a specific region/state is restricted.
        
        Args:
            country_code: Country code
            region_code: Region/state code (e.g., "CA" for California)
            
        Returns:
            Tuple of (is_restricted, reason)
        """
        # First check country-level
        country_restricted, country_reason = self.is_country_restricted(country_code)
        if country_restricted:
            return True, country_reason
        
        # Check US state restrictions
        if country_code == "US" and region_code:
            if region_code in self.restricted_us_states:
                state_name = self.restricted_us_states[region_code]
                return True, f"Online betting restricted in {state_name}"
        
        return False, "Region allowed"
    
    def check_access(self, country_code: str, region_code: str = None, ip_address: str = None) -> Dict:
        """
        Comprehensive access check combining geo-blocking and age verification prep.
        
        Args:
            country_code: User's country
            region_code: Optional region/state
            ip_address: Optional IP address for logging
            
        Returns:
            Access decision with details
        """
        # Check country restriction
        country_restricted, country_reason = self.is_country_restricted(country_code)
        
        # Check region restriction
        region_restricted, region_reason = self.is_region_restricted(country_code, region_code)
        
        is_blocked = country_restricted or region_restricted
        reason = region_reason if region_restricted else country_reason
        
        result = {
            "access_granted": not is_blocked,
            "country": country_code,
            "region": region_code,
            "ip_address": ip_address,
            "country_restricted": country_restricted,
            "region_restricted": region_restricted,
            "timestamp": datetime.now().isoformat()
        }
        
        if is_blocked:
            result["status"] = "blocked"
            result["reason"] = reason
            result["message"] = f"Access denied: {reason}"
        else:
            result["status"] = "allowed"
            result["reason"] = "No restrictions"
            result["message"] = "Access granted"
            result["next_step"] = "age_verification_required"
        
        # Log access attempt
        self._log_access_attempt(result)
        
        return result
    
    def add_to_whitelist(self, country_code: str):
        """Add country to whitelist (always allow)."""
        self.whitelisted_countries.add(country_code)
        self._save_custom_restrictions()
    
    def add_custom_restriction(self, country_code: str, reason: str):
        """Add custom country restriction."""
        self.restricted_countries[country_code] = reason
        self._save_custom_restrictions()
    
    def _load_custom_restrictions(self):
        """Load custom restrictions from file."""
        custom_file = self.storage_path / "custom_restrictions.json"
        
        if custom_file.exists():
            with open(custom_file, "r") as f:
                data = json.load(f)
                self.whitelisted_countries = set(data.get("whitelist", []))
                
                # Merge custom restrictions
                custom_restrictions = data.get("restrictions", {})
                self.restricted_countries.update(custom_restrictions)
    
    def _save_custom_restrictions(self):
        """Save custom restrictions to file."""
        custom_file = self.storage_path / "custom_restrictions.json"
        
        data = {
            "whitelist": list(self.whitelisted_countries),
            "restrictions": self.restricted_countries
        }
        
        with open(custom_file, "w") as f:
            json.dump(data, f, indent=2)
    
    def _log_access_attempt(self, result: Dict):
        """Log access attempt for compliance records."""
        log_file = self.storage_path / "geo_blocking_log.jsonl"
        
        log_entry = {
            "timestamp": result["timestamp"],
            "access_granted": result["access_granted"],
            "country": result["country"],
            "region": result.get("region"),
            "ip_address": result.get("ip_address"),
            "status": result["status"],
            "reason": result["reason"]
        }
        
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")


class ComplianceManager:
    """
    Unified compliance manager combining age verification and geo-blocking.
    
    Usage:
        compliance = ComplianceManager()
        
        # Check access
        result = compliance.check_user_access(
            user_id="user123",
            country="US",
            region="NJ",
            date_of_birth="1990-05-15",
            ip_address="192.168.1.1"
        )
        
        if result["access_granted"]:
            # Allow access to prediction services
            pass
        else:
            # Deny access with reason
            print(result["message"])
    """
    
    def __init__(self, storage_path: str = "compliance_data"):
        self.age_verification = AgeVerificationSystem(storage_path)
        self.geo_blocking = GeoBlockingSystem(storage_path)
        self.storage_path = Path(storage_path)
        self.storage_path.mkdir(parents=True, exist_ok=True)
    
    def check_user_access(self, 
                         user_id: str,
                         country_code: str,
                         date_of_birth: str = None,
                         region_code: str = None,
                         ip_address: str = None) -> Dict:
        """
        Complete compliance check for user access.
        
        Args:
            user_id: Unique user identifier
            country_code: User's country (ISO 3166-1 alpha-2)
            date_of_birth: User's DOB (YYYY-MM-DD) - optional if already verified
            region_code: Optional region/state code
            ip_address: Optional IP address for logging
            
        Returns:
            Complete compliance decision
        """
        result = {
            "user_id": user_id,
            "timestamp": datetime.now().isoformat()
        }
        
        # Step 1: Geo-blocking check
        geo_result = self.geo_blocking.check_access(country_code, region_code, ip_address)
        result["geo_check"] = geo_result
        
        if not geo_result["access_granted"]:
            result["access_granted"] = False
            result["status"] = "blocked_geo"
            result["message"] = geo_result["message"]
            result["block_reason"] = "geographic_restriction"
            return result
        
        # Step 2: Check for existing verification
        stored_verification = self.age_verification.check_stored_verification(user_id)
        
        if stored_verification and stored_verification.get("verified"):
            # User already verified
            result["access_granted"] = True
            result["status"] = "approved"
            result["message"] = "Access granted (previously verified)"
            result["verification_source"] = "stored"
            return result
        
        # Step 3: Age verification required
        if not date_of_birth:
            result["access_granted"] = False
            result["status"] = "pending_verification"
            result["message"] = "Age verification required"
            result["next_step"] = "provide_date_of_birth"
            result["block_reason"] = "age_verification_pending"
            return result
        
        # Step 4: Perform age verification
        age_result = self.age_verification.verify_age(date_of_birth, country_code, region_code)
        result["age_check"] = age_result
        
        if not age_result["verified"]:
            result["access_granted"] = False
            result["status"] = "blocked_age"
            result["message"] = age_result["message"]
            result["block_reason"] = "age_requirement_not_met"
            return result
        
        # Step 5: Store verification for future sessions
        self.age_verification.store_verification(user_id, age_result)
        
        # All checks passed
        result["access_granted"] = True
        result["status"] = "approved"
        result["message"] = "Access granted - all compliance checks passed"
        result["age_verified"] = True
        result["geo_allowed"] = True
        
        return result
    
    def get_compliance_summary(self) -> Dict:
        """Get summary of compliance system status."""
        return {
            "restricted_countries_count": len(self.geo_blocking.restricted_countries),
            "restricted_us_states_count": len(self.geo_blocking.restricted_us_states),
            "whitelisted_countries_count": len(self.geo_blocking.whitelisted_countries),
            "supported_jurisdictions": len(self.age_verification.age_requirements),
            "storage_path": str(self.storage_path)
        }


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("COMPLIANCE SYSTEM TEST")
    print("="*70)
    
    compliance = ComplianceManager()
    
    # Test 1: Allowed user (UK, 25 years old)
    print("\n[Test 1] UK user, 25 years old")
    result1 = compliance.check_user_access(
        user_id="user_uk_001",
        country_code="GB",
        date_of_birth="1999-01-15",
        ip_address="81.2.69.142"
    )
    print(f"  Status: {result1['status']}")
    print(f"  Access: {'GRANTED' if result1['access_granted'] else 'DENIED'}")
    print(f"  Message: {result1['message']}")
    
    # Test 2: Blocked country (UAE)
    print("\n[Test 2] UAE user (restricted country)")
    result2 = compliance.check_user_access(
        user_id="user_ae_001",
        country_code="AE",
        date_of_birth="1990-05-20",
        ip_address="5.62.60.1"
    )
    print(f"  Status: {result2['status']}")
    print(f"  Access: {'GRANTED' if result2['access_granted'] else 'DENIED'}")
    print(f"  Message: {result2['message']}")
    
    # Test 3: Underage user (US, 17 years old)
    print("\n[Test 3] US user, 17 years old (underage)")
    result3 = compliance.check_user_access(
        user_id="user_us_underage",
        country_code="US",
        region_code="NJ",
        date_of_birth="2007-06-10",
        ip_address="72.229.28.185"
    )
    print(f"  Status: {result3['status']}")
    print(f"  Access: {'GRANTED' if result3['access_granted'] else 'DENIED'}")
    print(f"  Message: {result3['message']}")
    
    # Test 4: Restricted US state (Hawaii)
    print("\n[Test 4] Hawaii user (restricted state)")
    result4 = compliance.check_user_access(
        user_id="user_hi_001",
        country_code="US",
        region_code="HI",
        date_of_birth="1995-03-22",
        ip_address="72.193.253.1"
    )
    print(f"  Status: {result4['status']}")
    print(f"  Access: {'GRANTED' if result4['access_granted'] else 'DENIED'}")
    print(f"  Message: {result4['message']}")
    
    # Test 5: Compliant user (New Jersey, 25 years old)
    print("\n[Test 5] New Jersey user, 25 years old (compliant)")
    result5 = compliance.check_user_access(
        user_id="user_nj_001",
        country_code="US",
        region_code="NJ",
        date_of_birth="1999-08-30",
        ip_address="72.229.28.185"
    )
    print(f"  Status: {result5['status']}")
    print(f"  Access: {'GRANTED' if result5['access_granted'] else 'DENIED'}")
    print(f"  Message: {result5['message']}")
    
    # Print compliance summary
    print("\n" + "="*70)
    print("COMPLIANCE SYSTEM SUMMARY")
    print("="*70)
    summary = compliance.get_compliance_summary()
    print(f"Restricted Countries: {summary['restricted_countries_count']}")
    print(f"Restricted US States: {summary['restricted_us_states_count']}")
    print(f"Whitelisted Countries: {summary['whitelisted_countries_count']}")
    print(f"Supported Jurisdictions: {summary['supported_jurisdictions']}")
    print(f"Storage Path: {summary['storage_path']}")
    
    print("\n✅ Compliance system test complete!")
