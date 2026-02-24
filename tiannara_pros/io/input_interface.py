class InputInterface:
    """
    Placeholder input provider.
    Later:
    - EMG decoder
    - BCI stream
    - sensor fusion
    """

    def get_next(self):
        """
        Returns a dict like:
        {
          "joint_angles": [...],
          "tags": [...],
          "intent_hint": "optional"
        }
        """
        raise NotImplementedError
