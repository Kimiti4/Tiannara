import json

class JsonlLogger:
    def __init__(self, path="tiannara_actions.jsonl"):
        self.path = path

    def send(self, packet):
        with open(self.path, "a", encoding="utf-8") as f:
            f.write(json.dumps(packet) + "\n")
