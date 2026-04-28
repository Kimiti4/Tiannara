import numpy as np


def trace_to_matrix(trace):
    # Convert trace → feature matrix
    data = []

    for step in trace:
        row = list(step.values())
        row = row[:10] + [0] * (10 - len(row))
        data.append(row)

    return np.array(data)