class LongHorizonMemory:

    def __init__(self):
        self.experiences = []

    def store(self, data):
        self.experiences.append(data)

    def retrieve_recent(self, n=5):
        return self.experiences[-n:]

    def get_best(self):
        return sorted(self.experiences, key=lambda x: x.get("score", 0), reverse=True)[:5]