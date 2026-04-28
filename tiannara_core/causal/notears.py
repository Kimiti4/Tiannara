import numpy as np


class NotearsCausalDiscovery:
    def __init__(self, lr=0.01, lambda_reg=0.01, max_iter=100):
        self.lr = lr
        self.lambda_reg = lambda_reg
        self.max_iter = max_iter

    def _h(self, W):
        # Acyclicity constraint (trace exponential)
        return np.trace(np.linalg.matrix_power(W * W, 2)) - W.shape[0]

    def fit(self, X):
        d = X.shape[1]
        W = np.zeros((d, d))

        for _ in range(self.max_iter):
            grad = -np.dot(X.T, X - X @ W) / X.shape[0]
            grad += self.lambda_reg * np.sign(W)

            W -= self.lr * grad

            # Enforce acyclicity constraint (soft)
            if self._h(W) > 1e-5:
                W *= 0.9

        self.W = W
        return W

    def get_edges(self, threshold=0.1):
        edges = []
        for i in range(self.W.shape[0]):
            for j in range(self.W.shape[1]):
                if abs(self.W[i, j]) > threshold:
                    edges.append((i, j, self.W[i, j]))
        return edges