# Certification Signing Authority (Phase 20.999)

## Purpose

Define the authority model for cryptographic signing of the constitutional certification. The signing authority confirms that the freeze is authentic and authorized.

## Signing Roles

| Role | Authority | Required |
|------|-----------|----------|
| Constitutional Architect | Design authority for the COS | Required |
| Council Member | Representative of constitutional council | Required |
| Human Authority | Ultimate human oversight | Required |
| System | Self-certification by the system | Optional (additional) |

## Signing Procedure

1. ConstitutionalFreeze record is presented to each signer
2. Signer verifies freeze hash by inspecting archaeology
3. Signer generates cryptographic signature of freeze_hash
4. Signature recorded in CertificationSignature record
5. All required signatures collected before declaration

## Signature Properties

- **Deterministic** — Signature is a deterministic function of freeze_hash and signer identity
- **Content-Addressed** — Each signature record has a unique fingerprint
- **Verifiable** — Anyone can verify the signature against the freeze hash
- **Witnessable** — Additional witnesses can co-sign
- **Archaeological** — Signature records preserved permanently

## Signature Record

CertificationSignature contains:
- Signature ID (content-addressed)
- Certification generation
- Freeze hash being signed
- Signer identity
- Signer role
- Signature method
- Signature value
- Signature hash
- Timestamp (deterministic)
- Witness references (optional)
- Fingerprint
