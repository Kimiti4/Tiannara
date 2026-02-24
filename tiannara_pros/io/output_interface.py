class OutputInterface:
    """
    Placeholder output sink.
    Later:
    - motor controller (CAN/I2C/UART)
    - actuator driver
    - ROS topic publisher
    """

    def send(self, action_packet):
        """
        action_packet like:
        {
          "mode": "...",
          "intent": "...",
          "targets": {...}
        }
        """
        raise NotImplementedError
