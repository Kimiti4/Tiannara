# Test the Requirements Extractor directly

goal = "Build an account service where user_id must be unique and balance cannot go below zero. Must respond in under 100ms."

IO.puts("\nTesting Requirements Extractor")
IO.puts("Goal: #{goal}\n")

world = Tiannara.ASC.Requirements.Extractor.extract(goal)

IO.inspect(world.invariants, label: "Invariants")
IO.inspect(world.capabilities, label: "Capabilities")
IO.inspect(world.constraints, label: "Constraints")
IO.inspect(world.risks, label: "Risks")

surface = Tiannara.ASC.ProjectWorld.requirements_surface(world)
IO.inspect(surface, label: "Requirements Surface")
