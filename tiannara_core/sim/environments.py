from __future__ import annotations

import random


def _input_size(agent) -> int:
    return max(1, int(getattr(agent, "input_size", 5) or 5))


def _forward(agent, x) -> list[float]:
    output = [float(value) for value in agent.forward(x)]
    return output or [0.0]


def _random_vector(size: int, scale: float = 1.0) -> list[float]:
    return [random.gauss(0.0, scale) for _ in range(size)]


def _match_target(x, size: int) -> list[float]:
    values = [float(value) for value in x]
    if not values:
        values = [0.0]
    if len(values) >= size:
        return values[:size]

    matched = list(values)
    while len(matched) < size:
        matched.append(values[len(matched) % len(values)])
    return matched


def _clip_score(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


def _mean_abs_diff(a, b) -> float:
    pairs = list(zip(a, b))
    if not pairs:
        return 1.0
    return sum(abs(left - right) for left, right in pairs) / len(pairs)


def _variance(rows: list[list[float]]) -> float:
    if not rows or not rows[0]:
        return 1.0

    width = len(rows[0])
    means = [sum(row[index] for row in rows) / len(rows) for index in range(width)]
    total = 0.0
    count = 0
    for row in rows:
        for index, value in enumerate(row):
            total += (value - means[index]) ** 2
            count += 1
    return total / max(1, count)


def control_task(agent) -> float:
    x = _random_vector(_input_size(agent))
    out = _forward(agent, x)
    target = _match_target(x, len(out))
    error = _mean_abs_diff(out, target)
    return _clip_score(1.0 - error)


def stability_task(agent) -> float:
    x = _random_vector(_input_size(agent))
    outputs = []
    for _ in range(5):
        noisy = [value + random.gauss(0.0, 0.1) for value in x]
        outputs.append(_forward(agent, noisy))
    variance = _variance(outputs)
    return _clip_score(1.0 - variance)


def energy_efficiency_task(agent) -> float:
    x = _random_vector(_input_size(agent))
    out = _forward(agent, x)
    energy = sum(abs(value) for value in out)
    return _clip_score(1.0 / (1.0 + energy))
