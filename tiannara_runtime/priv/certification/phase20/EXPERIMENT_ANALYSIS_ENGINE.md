# Phase 20.7 — Experiment Analysis Engine

## Role

The Experiment Analysis Engine processes raw experimental observations through deterministic statistical methods and produces structured results with quantified confidence. Analysis is fully deterministic — same observations always produce identical statistics and conclusions.

## Inputs

- ExperimentRun (raw observations, execution trace)
- ExperimentPlan (statistical plan, success/failure criteria)
- Constitutional statistical requirements

## Outputs

- StatisticalReport with test statistics, confidence intervals, effect sizes, conclusions
- ResultClassification (confirmed, refuted, inconclusive, ambiguous, error)

## Analysis Pipeline

### Step 1 — Data Validation
Validate observation data before analysis.

| Check | Description |
|-------|-------------|
| Completeness | All expected observations present |
| Integrity | No corrupted or missing data |
| Consistency | Observations internally consistent |
| Range | Observations within expected ranges |

### Step 2 — Descriptive Statistics
Compute descriptive statistics for all variables.

| Statistic | Description |
|-----------|-------------|
| Mean | Arithmetic mean per group |
| Variance | Variance per group |
| Standard deviation | Standard deviation per group |
| Sample size | Number of observations per group |
| Missing data | Count and pattern of missing data |

### Step 3 — Assumption Verification
Verify statistical assumptions before hypothesis testing.

| Assumption | Test | Pass/Fail |
|------------|------|-----------|
| Normality | Shapiro-Wilk or equivalent | Must pass or use non-parametric alternative |
| Homogeneity of variance | Levene's test | Must pass or use corrected test |
| Independence | Dependency check | Must pass |
| Sphericity (if repeated measures) | Mauchly's test | Must pass or use correction |

### Step 4 — Hypothesis Testing
Apply specified hypothesis tests.

| Test Type | Application |
|-----------|-------------|
| t-test | Comparison of two group means |
| ANOVA | Comparison of multiple group means |
| Chi-square | Categorical data analysis |
| Regression | Relationship between variables |
| Non-parametric | Alternative when assumptions violated |
| Bayesian | Alternative with prior incorporation |

Each test produces:
- Test statistic
- Degrees of freedom
- p-value
- Effect size
- Confidence interval

### Step 5 — Multiple Comparison Correction
Apply correction when multiple hypotheses are tested.

| Method | Application |
|--------|-------------|
| Bonferroni | Conservative correction |
| Holm-Bonferroni | Step-down correction |
| Benjamini-Hochberg | FDR control |
| Custom | Defined in statistical plan |

### Step 6 — Power Analysis
Compute achieved statistical power.

| Metric | Description |
|--------|-------------|
| Achieved power | Post-hoc power based on observed effect size |
| Minimum detectable effect | Smallest effect detectable with achieved power |
| Sensitivity | Sensitivity of design to various effect sizes |

### Step 7 — Result Classification
Classify the experimental result.

| Classification | Criteria |
|----------------|----------|
| Confirmed | Hypothesis supported, p < threshold, power adequate |
| Refuted | Hypothesis not supported, p >= threshold |
| Inconclusive | Insufficient power, ambiguous results |
| Ambiguous | Contradictory results across measures |
| Error | Analysis failed, assumptions violated |

### Step 8 — Report Generation
Generate complete statistical report.

| Section | Content |
|---------|---------|
| Data summary | Descriptive statistics |
| Assumption verification | Results of assumption checks |
| Hypothesis tests | Test results with statistics |
| Effect sizes | Effect size estimates with confidence intervals |
| Power analysis | Achieved power and sensitivity |
| Classification | Final result classification |
| Conclusions | Interpreted conclusions |
| Limitations | Identified limitations and caveats |

## Analysis Determinism

- All statistical computations are deterministic
- Random-like methods (bootstrapping, MCMC) use deterministic seeds
- Ties are broken deterministically (by observation_id)
- Same observations always produce identical statistics and classification

## Output Format

The StatisticalReport and ResultClassification are immutable, content-addressed objects:

| Field | Description |
|-------|-------------|
| report_id | Content-addressed identifier |
| experiment | Reference to ExperimentRun |
| descriptive_statistics | Descriptive statistics per variable |
| assumption_verification | Assumption check results |
| hypothesis_tests | Hypothesis test results |
| multiple_comparison | Multiple comparison correction results |
| power_analysis | Achieved power and sensitivity |
| classification | Result classification |
| conclusions | Interpreted conclusions |
| limitations | Identified limitations |
| fingerprint | SHA-256 of canonical form |
