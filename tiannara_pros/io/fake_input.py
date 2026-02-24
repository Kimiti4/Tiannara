import random

class FakeInput(InputInterface := object):
    """
    Simple generator to simulate prosthetic intent contexts.
    """

    def __init__(self):
        self.stream = (
            [["precision"]] * 10 +
            [["hand"]] * 6 +
            [["balance"]] * 8 +
            [["unknown"]] * 6 +
            [["precision"]] * 8
        )
        self.i = 0

    def get_next_tags(self):
        if self.i >= len(self.stream):
            return None
        tags = self.stream[self.i]
        self.i += 1
        return tags

    def get_next(self):
        tags = self.get_next_tags()
        if tags is None:
            return None

        # simulated angles (noise)
        joint_angles = [10 + random.uniform(-1, 1), 20 + random.uniform(-1, 1), 30 + random.uniform(-1, 1)]

        return {
            "joint_angles": joint_angles,
            "tags": tags
        }
