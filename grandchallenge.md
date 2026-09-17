![Image](https://images.openai.com/static-rsc-4/4YlLpdjyxMbmz2iScLbChUSRDsX_6cksdTHRjF1yQeh3PMXkEpFKH4qDR9N-or4OVr8c1Ccv3Ml74WZjXr9hRqpZKirgWkJtnloQs0WxAsCpUZKiuDAE2HE3wq0Xl0sVjtwXQCnuOjoIsexMFvbCUmVUAwWssOHEnlUuZOrSiHJ6u7wANmcsDi7rIRFX-WxM?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/BU8CTA1NHxsmQ5WdGx46AqMS4q7qfNSUIPII0ZQ7jnVJ-Q86wMGf_FqlS-Q3q0KEgKDjOhY9La8oFJZQ31q3-FhF0gEEMYYrtw3Z3xqM3PEuj7GB865X9QI1hbDzpTegh5jtnHeebtm8tvX2Bls9j4iE3WNVxqAsOgg-4X3lYe6oQkemzSy8IaM2dX_wL18S?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/dRbo2UNArSrA_J2vo5o51YkfgPWM2YKTU5BgtSpp1Y5tAf_c1VDDo_UzHlhuaC5Wwspukte6pnZ6IhcAWwUIua5dVYKU4WID_7RU1nSdjKePz5Uexa9dWzMHMBFg-r8QMFkf0a0FiiWWbodRQH74boxDZhZvoAqHHAhc-I662Oyb7EvXGrzMwgwvlGIdNMr9?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/qBjbgJTSqt8f3CzzfNyiL1_SDTyLIxsLslR7FONKGABkQeDsKdN9tJSDud6VjE4J4zU3u1gMq98Qbru3gbYEqRMm7dh5Uf03hfcTYJ7hhV1GuTXmdREJDdJoAGGAwCLf1zBleQvJH4frF6pvMvWbG59eBvF1jjnMrHCsYs7TB0CAi_gk0Z1FaeAMqecwoPwM?purpose=fullsize)

## P versus NP problem

The **P versus NP problem** is a central unsolved question in theoretical computer science and mathematics. It asks whether every problem whose solution can be quickly verified by a computer can also be quickly solved by a computer—that is, whether the complexity classes P and NP are actually the same. It is one of the seven **Millennium Prize Problem**, each worth $1 million for a correct solution .

### Key facts

* **Field:** Computational complexity theory
* **Formulated by:** Stephen Cook (1971)
* **Core question:** Is P = NP or P ≠ NP?
* **Prize:** US $1 million (Clay Mathematics Institute)
* **Consensus:** Most experts believe P ≠ NP

### Definition of P and NP

Class **P** contains problems solvable in *polynomial time* by a deterministic Turing machine—those efficiently computable in practice, such as sorting or finding shortest paths.
Class **NP** contains problems whose solutions, once proposed, can be verified in polynomial time. Typical examples include Boolean satisfiability (SAT), the traveling salesperson problem (decision form), and Sudoku verification .

### Significance

If P = NP, every efficiently verifiable problem would also be efficiently solvable, implying fast algorithms for thousands of difficult tasks and undermining the security of modern cryptography, which relies on the presumed hardness of NP problems such as integer factorization.
If P ≠ NP, it would confirm that some problems are inherently intractable to solve exactly in reasonable time .

### Historical background

The conceptual roots trace to a 1956 letter from Kurt Gödel to John von Neumann asking whether certain proof tasks could be done quickly. In 1971, Cook formally posed the problem and proved the Boolean satisfiability problem to be NP-complete, showing that many difficult problems share a common complexity core .

### Current status and impact

No proof exists for either P = NP or P ≠ NP. Resolving it would reshape computing, optimization, artificial intelligence, economics, and the philosophy of mathematical proof itself .

![Image](https://www.researchgate.net/publication/349466484/figure/fig11/AS%3A993602658385923%401613904742975/Polar-plot-of-the-Riemann-zeta-function-restricted-to-the-critical-line-ie-z1-2-i.ppm)

![Image](https://upload.wikimedia.org/wikipedia/commons/8/82/Georg_Friedrich_Bernhard_Riemann.jpeg)

![Image](https://www.researchgate.net/publication/340943543/figure/fig2/AS%3A11431281431728455%401746816151915/Critical-strip-and-critical-line-on-the-C-plane-with-the-four-associated-points.tif)

![Image](https://mathworld.wolfram.com/images/eps-svg/CriticalStrip_1000.svg)

![Image](https://www.researchgate.net/publication/327043089/figure/fig2/AS%3A659964750221321%401534359266794/The-critical-strip-of-s-Image-from-fieldofsciencecom-9.png)

## Riemann Hypothesis

The **Riemann Hypothesis** is a foundational conjecture in number theory proposed by Bernhard Riemann in 1859. It concerns the zeros of the **Riemann zeta function**, asserting that all nontrivial zeros lie on the “critical line” in the complex plane where the real part of the argument equals one-half. It remains unsolved and is one of the seven Clay Mathematics Institute Millennium Prize Problems.

### Key facts

* **Proposed by:** Bernhard Riemann, 1859
* **Mathematical object:** Riemann zeta function ζ(s)
* **Core statement:** All nontrivial zeros satisfy Re(s) = 1/2
* **Status:** Unproven (as of 2026); extensive numerical verification
* **Prize:** $1 million Millennium Prize for proof or disproof

### Background and statement

The Riemann zeta function,
[
\zeta(s) = \sum_{n=1}^{\infty} \frac{1}{n^s},
]
initially defined for complex numbers with real part greater than 1, extends to most of the complex plane through analytic continuation. Its “trivial zeros” occur at negative even integers. Riemann hypothesized that all **nontrivial zeros**—solutions where ζ(s)=0 in the strip 0 < Re(s) < 1—lie on the line Re(s)=½. This critical line’s zeros encode deep information about the distribution of prime numbers. ([Encyclopedia Britannica][1])

### Significance in number theory

A proof of the hypothesis would sharpen estimates in the **Prime Number Theorem**, yielding optimal error bounds for how primes are distributed among integers. It would also confirm many conditional results in analytic number theory involving the Möbius function, divisor sums, and gaps between primes. Equivalent formulations tie the hypothesis to bounds on arithmetic functions and to probabilistic models of prime randomness. ([Scientific Library][2])

### Mathematical and computational progress

Since Riemann’s paper *“Über die Anzahl der Primzahlen unter einer gegebenen Grösse”*, thousands of mathematicians have tested and extended his ideas. In 1914, G. H. Hardy proved infinitely many zeros lie on the critical line, and subsequent results show a large proportion must do so. High-performance computations have verified billions—and now trillions—of zeros on the line, with none off it, but such checks do not constitute proof. ([LinkedIn][3])

### Broader impact and current status

Beyond number theory, the Riemann Hypothesis connects to **quantum physics**, **random matrix theory**, and **cryptography**. It forms part of **Hilbert’s eighth problem** and influences modern fields such as spectral theory and noncommutative geometry. Despite immense progress, no rigorous proof or counterexample has been accepted; it remains the “holy grail” of mathematics. ([HandWiki][4])

[1]: https://www.britannica.com/science/Riemann-hypothesis?utm_source=chatgpt.com "Riemann hypothesis | Prime Numbers, Zeta Function & Complex Analysis | Britannica"
[2]: https://www.scientificlib.com/en/Mathematics/LX/RiemannHypothesis.html?utm_source=chatgpt.com "Riemann hypothesis"
[3]: https://www.linkedin.com/posts/david-steenhoek-a681a69_the-riemann-hypothesis-often-abbreviated-activity-7409475838741536768-Jdzi?utm_source=chatgpt.com "Riemann Hypothesis: Unsolved Math Problem | David Steenhoek posted on the topic | LinkedIn"
[4]: https://handwiki.org/wiki/Riemann_hypothesis?utm_source=chatgpt.com "Riemann hypothesis - HandWiki"

![Image](https://images.openai.com/static-rsc-4/hy5WFXg_xabprav_-d0nHxJDkynSZrgc_NtS88MQNlpNxUO-L9iO6OO___nU3nosJJK4OqWxNYSIXCpHqbfAnTt6Izx01F082i9WMW0A7B6Ikp_61NkVI_DzAp7cUCLPV7YrMa1KGRx0fnlX44lD0GBZOifiR7pdyiCR1L2rWJeFWkNwxxMrKlN8hXDpYO-h?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/MgQnd7ZOEDI8YVmEslInhciWRAEqRA8xJwAl6fXL9bkcR85o03GfWGvMMejnanvFSm5yHeuE87pCr7URf5qKnu4HFJ7i550ACOp44_XOiv3SPWd7KhDXqszCxl00Qaa7bWExsirNb_OBfPUF24WDouSFeuu4LVrFL5M1C7EykEoKofX3YXOifTq_eHu1lICG?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/O8OGTG88d7MSeytqtVd3-Gi7Y3fvPUdK6yIMvyo-OhI9tMiREQuUDCgSzisEldPTV2F-Gvhqg5N90XHZppLyAZDOzoyuvoEab3PJ-pVMW02i3UBwD23n1QYOXNU90s7cXL_vIKxtavX9SRbn52wTvTTsmiP1X6jzKT5j5tmFI5DEC3qewk3v9xJz90ry0cnI?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/aXxdzEmbPP5T7QWeeiRbUJaz20mX-ZA3V5QcwmzkM8GUpsYNO9Z0isp9c6ZWFbQAmSgcSe2zSAZH7_9cIXaEhPNq6jRP-G0jfEovrOZsAFLQD36ouS414wbIN3Tf9NR15Z9G0Htyz29n3Kw4khDyRahb1CB93b4Z8XVccx66jxhLgzeFgG4KwO3qneHU5WPl?purpose=fullsize)

## Yang–Mills Existence and Mass Gap

The **Yang–Mills Existence and Mass Gap** is one of the seven Millennium Prize Problems posed by the Clay Mathematics Institute in 2000. It asks for a rigorous mathematical construction of a four-dimensional quantum Yang–Mills theory that both exists and exhibits a **mass gap**—a positive lower bound for the energy of excitations above the vacuum state.

### Key facts

* **Defined by:** Arthur Jaffe and Edward Witten (2000)
* **Prize:** US $1 million for a valid proof
* **Requirement:** Existence of a quantum Yang–Mills theory on ℝ⁴ for any compact simple gauge group G
* **Condition:** Theory must satisfy axioms of constructive/axiomatic QFT and possess Δ > 0 mass gap
* **Status (2026):** Unsolved

### Background

Proposed by Chen-Ning Yang and Robert Mills in 1954, Yang–Mills theories generalize electromagnetism by replacing its abelian symmetry with non-abelian Lie groups such as SU(2) or SU(3). These gauge theories underpin the **Standard Model** of particle physics, governing the strong, weak, and electromagnetic forces. Although experimentally successful, their full mathematical foundation remains incomplete: physicists can compute with them perturbatively or on lattices, but a rigorous continuum proof of existence has not been established.

### The mass gap

In quantum field theory, the **mass gap** Δ is the smallest positive energy eigenvalue of the Hamiltonian H. Physically, it means all excitations—such as **glueballs** in pure SU(3) Yang–Mills—have non-zero mass, explaining why the strong nuclear force is short-ranged. Lattice simulations support Δ > 0, but the proof must show this rigorously in four-dimensional Euclidean space under the Wightman or Osterwalder–Schrader axioms.

### Significance

Solving this problem would place **quantum chromodynamics (QCD)** on firm mathematical footing and illuminate deep links between geometry, topology, and quantum physics. It is regarded as a benchmark for reconciling physical intuition with rigorous analysis in non-perturbative field theory.

### Current research landscape

Numerous constructive and computational approaches—ranging from lattice gauge theory to modern functional-analytic, renormalization-group, and even quantum-information-theoretic formulations—have been explored. While several independent researchers have claimed progress or partial constructions, none has yet been verified or accepted by the mathematical physics community as a complete proof of the Clay problem .

![Image](https://images.openai.com/static-rsc-4/M6OPGid-p6kZaQ0ow2wMqmodXcfZbKMChGe-rcJT4unCNtZ8C_9S59wtq5W3XcYhAEPs4E9USQqZPBf5hYjd9EtKGQHFQS6k88wxIuIMqFjBp185KkwUlgRVrGZmaHFWlpQCS9lzPB4CdmHh5hjbx8XtRrXBu7hu7QZYFZM9prLPiDDpAU7jsvhQsslf4O_e?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/zAwLClPqBQatxqA_LHYxiogLObHmPcjgIusO1ezKwgQbr61XqgZ8vlF0vME7GQTxPpaqyBeRKGUtTKiF1Mu-5EjjkrjjoJW0VUbFEZAjhbWq408ZX1m-2LDtsmNvhgu_BuZFxfCPlitDKChpuUa8gxGrJtXER9ksQC1vRcmL5WIvoJsiX9RxdRbIw6QGcI20?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/3t_xObN_lRKZDTE2mhIdZOPl7tNpIJuMI3KGvesC-Cvpr6Xz67JT8P5ap8zSIhHBdEJHW7XWtR4Y7v3cytAKuQsaygxGu2Qtyx7NfVpDVh5uJxLpCMD3k6tVV2TzRIPyru52kAhcNRGdHhRDBunskyly-lBtBk71frn2JKuK0PQXtcxrf7-JfHI0Ua7hrDAh?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/ZHHENung0_I7L2o-2WwH9MqyBh8_LLEr118cGfozPAMdtZKycAd-gfwmkFj0K_KVNwWjlU8awmDlwSyxELHVU5j56OR71lr7yYB8P-JDrwxdUg9UQ6yfb3f9r1EMyLFEcjaSBnMKL1OzSuepc500E-t0lDkGybbyB-NldiZmCqh23SYwsd_cON0MZkF2L8dS?purpose=fullsize)

## Navier–Stokes existence and smoothness

The Navier–Stokes existence and smoothness problem is one of the seven Clay Mathematics Institute. It asks whether the three-dimensional incompressible Navier–Stokes equations always have smooth, globally defined solutions or can develop singularities in finite time. It remains one of the most important open questions in mathematical physics and analysis.

### Key facts

* **Formulated:** 2000 by the Clay Mathematics Institute
* **Prize:** US $1 million for a complete solution
* **Domain:** 3-D incompressible viscous fluid on ℝ³ or the 3-torus 𝕋³
* **Status:** Unsolved; partial results known for 2-D and special 3-D cases
* **Reference formulation:** C. Fefferman’s official statement (2000)

### Mathematical setting

The equations describe velocity **u(x,t)** and pressure **p(x,t)** of a viscous fluid:
[
\partial_t u + (u\cdot\nabla)u = -\nabla p + \nu \Delta u,\qquad \nabla\cdot u = 0,
]
with viscosity ν > 0.  The challenge is to prove or refute that, for any smooth divergence-free initial velocity with finite energy, there exist unique smooth functions u and p for all t ≥ 0.

### Known results

![Image](https://images.openai.com/static-rsc-4/6lFLIsZlHGGiS_ZHbBDN23_9GvrSLt4mXjiFJ1vfyWbbIU-RHZHxwYWn9tB_bwlR4-BOuHROrEIhymXxYcpUtGgpdknCZLiYRvl2CR9MRSz21O3dwK3uqQPjh2BRHVdQRsW9cdTROuYnW8iRdBrQ6K7Y4eAM5ra2-NZ5WjOjz8c7DGTQFErR3l1SmW1mRwi0?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/hPRzQ-bSvhK5zIeBsUCGahdsuWX--3iN7JoFcGl54eFgufI3RpG2QJzNq0Q66AeB54k-NBqrhv3F2hJ76anF69Fsh2RhVC8TQ5RsgAgz2eyTGiQ4bUyFC1UZ3t2oyUAR7i6i2tGA5YpPhGas7t3fuOTIbq8fjj5uZDgdDDwQYz8vQG0PASobPjpMnHZUTAjD?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/M6OPGid-p6kZaQ0ow2wMqmodXcfZbKMChGe-rcJT4unCNtZ8C_9S59wtq5W3XcYhAEPs4E9USQqZPBf5hYjd9EtKGQHFQS6k88wxIuIMqFjBp185KkwUlgRVrGZmaHFWlpQCS9lzPB4CdmHh5hjbx8XtRrXBu7hu7QZYFZM9prLPiDDpAU7jsvhQsslf4O_e?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/SM5YTflOS8txL6vWq9HlNfx18C3wVGJ8bsiEfHhTuy1qg_EZmzLuFiHMYBkBTpgk6G1dPOR5jeq67rEDAfNfTOQq9mgyDEOtlKuSjvWU8lHoTbD5EDAnOCUTUK5606T6FusiD1NRaTd4JiYvL4HpXTWIRgWS67nHrQu7u4ZyjreUtFu1w1DkshkC6z-fCacY?purpose=fullsize)

In two dimensions, global smooth solutions are established. For 3-D flows, Jean Leray (1934) proved the existence of weak (energy-bounded) solutions but not their smoothness or uniqueness. Subsequent work by Caffarelli, Kohn, and Nirenberg (1982) showed partial regularity, meaning singularities—if any—occupy a set of measure zero in space-time. No one has yet proved global smoothness or finite-time blow-up.

### Why it matters

The problem links rigorous mathematics with real-world turbulence. A proof of smoothness would validate the deterministic predictability of fluid motion; a counterexample would show that even simple physical laws can produce spontaneous breakdown of smooth behavior. Both outcomes would profoundly affect analysis, numerical modeling, and theoretical physics.

### Current research directions

Approaches span harmonic and geometric analysis, critical Sobolev spaces, energy methods, and probabilistic or computational models. Recent preprints and frameworks—including geometric (Hodge-theoretic) and motion-based formulations—seek new ways to bridge local and global behavior, but none has met the Clay criteria. As of 2026, the Navier–Stokes existence and smoothness problem remains unsolved.

![Image](https://images.openai.com/static-rsc-4/DLMC7u0OTaXSCKRW5OO3twyBAyoTrd6lJFPEgz5yFzcVqi_e4nYJ2MTVa8NRYvnyGW-TbOyLJ7Jdola6EHQhCSIChJQiYyx7IhwfgdtoiFbBN0vPUNr0fsaerPxZRQLt3yMgfqH-X1TjMxs13tzHMRQ1QlqIPpPSJfDIDokR06nPEMawykHn23K7MkG7LZ6T?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/Rg9wqrBV2Xm9dUTbMVE130uwmtzYbvvrE3SoJcKkCA3e61QkP1siMIORqd_Gy8sqlf1eCek_6dkTHCtOUL2vNABdQs-lHDtLeZm3ObteDTFUk5Lc7_WKoUweIxStrebRqzG6n4zYvpRhz9Sg1NrXy8eoElSrDUkY0PV41yRohFX2PGl-PZdjaVAwNwuQyz-Q?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/2Anzih5vr24frllaxlBge03tuU_7_RaXoPbYOdEUvSIl_CfeHsLXdqdN7q0zyG4VVqgd0VXox1qa_U1ct3eEWkBJO-N2M9zT_rAiXnsk4ugCH3De7DhRjpULfrO6vm50_uEwDJlDuWr2zg0iWyP4ebSjNYs-51I2T9kecmBEwJQoW6vfEDIwRQEWnQGUTcZS?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/WrT0Z60aiQTfQ8HbtlCfS0ZYkdgEMyYfIaOH7wOPXtT0iNon7ezFx9k8np78Iao-4Je2AWRv1hBuEeS97TBBCPEr1EpKOW_6gfs5bfu3blJAQQ9jGJ571xwGcy7J29hfYw19Ru0U_tMMs8CayXDiowg97ytMNPtetMjxbkAcPPJMvdYxLji-LAxYxTLsa0lE?purpose=fullsize)

## Birch and Swinnerton-Dyer Conjecture

The **Birch and Swinnerton-Dyer conjecture** is a central unsolved problem in modern number theory. It links the arithmetic of elliptic curves—cubic equations defining smooth curves with a group structure—to the analytic behavior of their associated L-functions. Proposed in the 1960s by British mathematicians Bryan Birch and Peter Swinnerton-Dyer, it is one of the seven Millennium Prize Problems, carrying a $1 million prize for a complete proof or disproof.

### Key facts

* **Field:** Number theory, algebraic geometry
* **Proposed:** Early 1960s, University of Cambridge
* **Core statement:** Rank of elliptic curve = order of zero of its L-function at s = 1
* **Millennium status:** Open problem (since 2000, Clay Math Institute)
* **Prize:** US $1 million for a full solution

### Mathematical content

For an elliptic curve E defined over the rational numbers, the conjecture asserts that the number of independent rational points of infinite order (the **rank** r of E (ℚ)) equals the **order of vanishing** of its Hasse–Weil L-function L(E,s) at s = 1.
Formally:
r = ordₛ₌₁ L(E,s).
If L(E,1) ≠ 0 then E(ℚ) is finite; if L(E,1) = 0, E has infinitely many rational points.

### Historical development

Birch and Swinnerton-Dyer based their conjecture on numerical experiments using Cambridge’s EDSAC computer. Later advances included partial proofs: the Coates–Wiles theorem (1976), Gross–Zagier (1983), and Kolyvagin (1990), which confirmed the conjecture for modular elliptic curves of ranks 0 and 1. The modularity theorem (Wiles et al., 1999) established the analytic continuation of L(E,s), enabling the conjecture’s full formulation.

### Importance and current status

The conjecture connects deep analytic and arithmetic properties, influencing research in algebraic geometry, modular forms, and cryptography. Despite major progress in special cases, no general proof exists for curves of rank ≥ 2. It remains one of mathematics’ most profound open problems and a benchmark for advances in arithmetic geometry.


![Image](https://images.openai.com/static-rsc-4/gbtNW0DiUyKtz5yottTUH2xoxgdDqGU9Y-XVI5fGw4C62_Gze5wBXP0jZCJbyCNRefcZfeB93ivK-bT3G5ulttr6CfLoFIbgp6RsJeqQVmjgN8mA2APtWlHsb65LOLI0GCKAPgyUQKe5HqBRz3mtAwxoLlludKrxoZguuzjkDgcW0SlfAW2vlrVitf3C4ccL?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/4fpZyu2V3rlKHyfpiZWzJimwkz1UWXcQsY58fVzkGc4I-pd6bV9H5n3w0QjAr1V6aenTiW7glohav_GZc4TB_vx2Tc2YxfYOMM-C21-cHnbYACasPVl-xKn1P9y5GMRPRgPO5V2OLDylss56XETReM-Gww8rK7QT4xRRbSB32WOMjljQKMvsccW2llwAY2bA?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/yLeeMHWsf5wCdg8unHxG6KRyM8Gm5Qg0U_53JqAC8sMSFeSfygXcegoKBIow3wOKXR7p028QGVoEzl6oNnW0ecF4F44QGyhYMiUwfFPHqEy5eeDuNBQYCW-oEeNJF7rsh53G_mQrLTCgVgoY5qPocRJCa3uEQM_ugd86HD0sB_h6GSuG_At6lnIP7XNOuJed?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/qBjbgJTSqt8f3CzzfNyiL1_SDTyLIxsLslR7FONKGABkQeDsKdN9tJSDud6VjE4J4zU3u1gMq98Qbru3gbYEqRMm7dh5Uf03hfcTYJ7hhV1GuTXmdREJDdJoAGGAwCLf1zBleQvJH4frF6pvMvWbG59eBvF1jjnMrHCsYs7TB0CAi_gk0Z1FaeAMqecwoPwM?purpose=fullsize)

## Hodge Conjecture

The Hodge Conjecture is a central open problem in algebraic geometry proposing a deep link between topology and algebraic geometry. It asserts that certain topological features of smooth projective algebraic varieties—called Hodge classes—are algebraic, meaning they can be expressed as rational combinations of geometric subvarieties. It is one of the seven **Millennium Prize Problems**, with a $1 million award for its solution.

### Key facts

* **Formulated by:** William V. D. Hodge (1941)
* **Domain:** Algebraic geometry, topology, complex analysis
* **Formal statement:** Every rational Hodge class on a smooth projective variety is algebraic
* **Prize designation:** Clay Mathematics Institute, 2000
* **Status:** Proven only in special cases

### Mathematical background

The conjecture arises from Hodge theory, which studies how complex differential forms decompose on Kähler manifolds. For a complex projective variety (X), cohomology groups (H^{p,q}(X)) encode geometric and analytic information. The conjecture claims that classes in (H^{2k}(X,\mathbb{Q})\cap H^{k,k}(X))—the so-called **Hodge classes**—are exactly those generated by algebraic cycles, or formal sums of subvarieties of codimension (k). This bridges continuous and algebraic descriptions of geometry.

### Historical development

Scottish mathematician **William Vallance Douglas Hodge** introduced the idea in the 1930s–40s, extending earlier work of Henri Poincaré and Solomon Lefschetz. Hodge formally presented it in 1950 at the International Congress of Mathematicians. In 2000, the **Clay Mathematics Institute** designated it a Millennium Problem for its foundational importance in understanding the geometry of complex varieties.

### Known results and significance

The conjecture is proven in low dimensions (for surfaces and certain threefolds) and for special varieties such as abelian varieties of low dimension, quadrics, and some Fermat hypersurfaces. It remains unproven in general, especially for fourfolds and higher. Its resolution would clarify the extent to which the topology of algebraic varieties is governed by algebraic equations—an insight expected to influence number theory, complex geometry, and even string theory.

### Contemporary research

Recent work continues to confirm the conjecture in specific contexts. For example, studies by Genival da Silva Jr. (2021) established new verified cases for Fermat fourfolds of certain degrees, extending results by Tetsuji Shioda and Noriyuki Aoki. Despite such progress, a general proof or counterexample remains elusive, preserving the Hodge Conjecture’s place as one of mathematics’ deepest unsolved challenges.


![Image](https://images.openai.com/static-rsc-4/KMztCR9mKVU4-spXvUN1c_ycD30nYgsF3aO8j2Oq9-4BSQTQkt49LjiWdphleBCr-_AZR5ooQsaJRZcDUDOl6RxGc_pTeBCOHK4ZC-R9wDXibdJftzOp6gJX_zowMu-cm9O9M3cedbQYYx4PTzZ82aw1CUDzm6Ck8xHxBUTeK4x-NLraI3w4wibMVzBrxztI?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/2_vb4dfOQKZoffwr1KK2gBW12w_tFkrVIwLQwl4or9oMRvpx7VnFB21nkV7XEQ9qESjLuqkv4h7EeeMf3xwZ2gqYlYVZ0LIrSG6TMWQ-N91RWkJCLu3H053VwvB2T8aADA_igfZRMjakJgSn-6aNZ9BMwh8MYvCpdOpEkLPGVUEbPDTsyJ7n9iqKByqsyx8B?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/d8GRHAS514cBYzOdahOOI8d6tkrZVJeSSddCItYceJK41SFquRwZ8vFoVCpnpZrAF8hjy7pyrHFYnzsak3L2Y0ozqVHCtV3Awy08bK6mCByeXAFJN2Vh0yOcdydwDnRpSMSTA_NmShkCl1yAeJtdDIQk_CS9dZHbmrNO0f-CIKrgHb803fwmjoBABAhTY_l6?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/ODre1u87zfKJH0w9Sn0WNqZYvI-xdYb7ropbeHrwjmm-GaPDf3vFhZxR1MNRGiP9CHc8uANcW-tIhqKy5ZqBw1mCQRDXMxcgFl4IafUifD_jbc2Wvh-2CoNKQj7CObMVlQpvTarO_1kAhX1oWIiCYBiHN1mZH68H7E8irPG92gH6BL8kZ6INxS9l9OcEDt_L?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/kUoCg_q6rSYF4wJrsLdYZtThZyapyhIHKjzvV1H0kgR_CpTeNgBZM9asvHqQ2aUS0sPOaX28ifqYtoUva5b2gsXwZX70NPo6cG8xPQoqb_PrFdYET3h0XaLuPjytsIflkFhoi0xtpw_w9XSK1vZdkjj3xFsuaE0s59_Uv3iGM4DCVL6BtL8p5iR2JcXnN3uO?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/n4qmK5sTL-k1B5AATrkH34ecHLm-WhJUiyt2GnXUmTGBDQ5RFVgRH_ZnfZ5uGU9Nd-BfbzN-6QQ7O_e3lKO9bZowsL67rsEcki5ofVfZmz7fGWYfGpgvdO0GkoCOEU19J1oHYiYdmeDHG9LvT5C8r-xBh2DEG1B9ZpO8YteO9O7nGrM-DmO-xWBFkBM3CfeR?purpose=fullsize)

## Poincaré Conjecture

The Poincaré Conjecture is a foundational result in topology, originally posed in 1904 by French mathematician Henri Poincaré. It asserts that every closed, simply connected three-dimensional manifold is homeomorphic to the three-sphere (S³). This statement, one of the most famous problems in mathematics, was solved a century later by Russian mathematician Grigori Perelman, marking the only fully resolved Clay Mathematics Institute.

### Key facts

* **Proposed:** 1904, by Henri Poincaré
* **Solved:** 2002–2003, by Grigori Perelman
* **Mathematical field:** Topology, 3-manifolds
* **Prize:** $1 million Millennium Prize (declined 2010)
* **Status:** Proven theorem

### Mathematical significance

The conjecture explores how three-dimensional spaces can be classified by their topological properties. A space is **simply connected** if any loop within it can be continuously shrunk to a point without leaving the space. Poincaré’s question asked whether this property uniquely characterizes the three-sphere among all closed 3-manifolds—a generalization of known results for the two-sphere.

### Path to solution

Progress came in higher dimensions during the 20th century: Stephen Smale proved the conjecture for dimensions ≥ 5 (1961) and Michael Freedman for dimension 4 (1982). The n = 3 case remained open until Perelman’s 2002–2003 preprints, which built on Richard Hamilton’s Ricci flow theory and confirmed William Thurston’s geometrization conjecture. Independent teams verified the proof by 2006.

### Impact and recognition

Perelman’s achievement earned him the 2006 Fields Medal (which he declined) and formal recognition by the Clay Mathematics Institute in 2010. His methods not only solved the Poincaré Conjecture but also transformed geometric analysis by demonstrating how Ricci flow and topological surgery can classify three-dimensional spaces.

### See also

* Ricci flow
* Geometrization conjecture
* Clay Mathematics Institute
