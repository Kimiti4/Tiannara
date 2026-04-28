import torch
import torch.nn as nn
import torch.nn.functional as F


class GNNReasoner(nn.Module):
    def __init__(self, input_dim=16, hidden_dim=32):
        super().__init__()

        self.fc1 = nn.Linear(input_dim, hidden_dim)
        self.fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.out = nn.Linear(hidden_dim, 1)

    def forward(self, x, adj):
        h = F.relu(self.fc1(x))

        # message passing
        h = torch.matmul(adj, h)

        h = F.relu(self.fc2(h))
        return self.out(h)


class GNNTrainer:
    def __init__(self):
        self.model = GNNReasoner()
        self.opt = torch.optim.Adam(self.model.parameters(), lr=1e-3)

    def train_step(self, node_features, adj, target):
        pred = self.model(node_features, adj)

        loss = ((pred - target) ** 2).mean()

        self.opt.zero_grad()
        loss.backward()
        self.opt.step()

        return loss.item()