
import time
from typing import Dict

class ContextProcessor:
    def process(self, sensor_data: Dict) -> Dict:
        return {
            "intent": sensor_data.get("intent", "unknown"),
            "stability": self.compute_stability(sensor_data),
            "timestamp": time.time()
        }

    def compute_stability(self, data: Dict) -> float:
        joint_angles = data.get("joint_angles", [])
        if not joint_angles:
            return 0.0
        mean = sum(joint_angles)/len(joint_angles)
        variance = sum((x - mean)**2 for x in joint_angles)/len(joint_angles)
        return max(0, 1 - variance/100)
