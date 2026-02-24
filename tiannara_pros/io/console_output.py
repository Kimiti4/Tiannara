class ConsoleOutput:
    def send(self, action_packet):
        print("OUTPUT:", action_packet)
import json

class ConsoleOutput:
    def send(self, action_packet):
        print("OUTPUT:", json.dumps(action_packet, indent=2))
