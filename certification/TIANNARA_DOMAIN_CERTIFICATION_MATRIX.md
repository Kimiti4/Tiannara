# Tiannara Domain Certification Matrix

**Baseline Commit:** 3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6  
**Timestamp:** 2026-08-25T00:15:00Z  

## Executive Summary

The architectural intent is for 20 specific constitutional domains to act as active research portfolios coordinated by the Meta-Science operating system. 
However, the implementation contains a critical contradiction: `DomainRegistry` lists legacy domains (`:science`, `:mathematics`) while omitting intended domains (`:physics`, `:chemistry`). 
Furthermore, while all 20 intended domains exist as files (`lib/tiannara/domains/*.ex`), they are currently implemented as mock/stub behaviours returning hardcoded metrics rather than executable research entities.

---

## 1. Architectural Discrepancies (EVID-0005)

**Intended Constitutional Domains:**
Engineering, Physics, Chemistry, Medicine, Cybernetics, Governance, Computation, Agriculture, Energy, Logistics, Cognition, Materials, Robotics, Economics, Philosophy, Sociology, Linguistics, Aerospace, Ecology, Architecture.

**Registered Domains (`lib/tiannara/os/domain_registry.ex`):**
Contains `:science` and `:mathematics`. Misses `:physics` and `:chemistry`.

---

## 2. Certification Matrix

| Domain | Registry | Ontology | Programs | Research | Experiments | Discoveries | Math Int. | Cross-Domain | Runtime | Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Engineering** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Physics** | **NO** | Partial | No | Mock | Mock | Mock | None | None | Unwired | `CONTRADICTED` |
| **Chemistry** | **NO** | Partial | No | Mock | Mock | Mock | None | None | Unwired | `CONTRADICTED` |
| **Medicine** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Cybernetics** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Governance** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Computation** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Agriculture** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Energy** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Logistics** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Cognition** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Materials** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Robotics** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Economics** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Philosophy** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Sociology** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Linguistics** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Aerospace** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Ecology** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |
| **Architecture** | Yes | Partial | No | Mock | Mock | Mock | None | None | Stubbed | `PLACEHOLDER` |

*(Note: `Science` and `Mathematics` exist in the registry but are Architecturally Contradicted by Phase 6/15 design)*

---

## 3. Evidence of Mocking (EVID-0006)

Domains implement `Tiannara.Domains.Domain` behaviour but return fixed structures rather than executing autonomous investigation:
```elixir
# Example from lib/tiannara/domains/medicine.ex
@impl true
def generate_hypotheses(_context), do: {:ok, []}

@impl true
def metrics do
  %{active_hypotheses: 205, open_experiments: 47, discoveries_this_cycle: 3}
end
```

**Conclusion:** The domains exist architecturally (as specifications and scaffolding) and are partially registered, but their internal research capability is missing or hardcoded. They are `PLACEHOLDER` components.
