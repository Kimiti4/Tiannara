def clip(x, lo, hi):
    return max(lo, min(hi, x))


def validate_and_clip(command: dict, limits: dict):
    mode = command.get("mode")
    targets = dict(command.get("targets", {}))  # copy

    if mode == "hand_control":
        targets["grip_force"] = clip(targets.get("grip_force", 0.0),
                                     limits["hand"]["grip_force_min"],
                                     limits["hand"]["grip_force_max"])
        targets["stiffness"] = clip(targets.get("stiffness", 0.0),
                                    limits["hand"]["stiffness_min"],
                                    limits["hand"]["stiffness_max"])
        targets["damping"] = clip(targets.get("damping", 0.0),
                                  limits["hand"]["damping_min"],
                                  limits["hand"]["damping_max"])

    elif mode == "stabilization":
        targets["damping"] = clip(targets.get("damping", 0.0),
                                  limits["stab"]["damping_min"],
                                  limits["stab"]["damping_max"])
        targets["correction_gain"] = clip(targets.get("correction_gain", 0.0),
                                          limits["stab"]["correction_gain_min"],
                                          limits["stab"]["correction_gain_max"])
        targets["tremor_filter"] = clip(targets.get("tremor_filter", 0.0),
                                        limits["stab"]["tremor_filter_min"],
                                        limits["stab"]["tremor_filter_max"])

    safe = dict(command)          # copy outer dict too
    safe["targets"] = targets
    return safe