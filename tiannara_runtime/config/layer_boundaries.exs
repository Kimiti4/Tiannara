# Prevent L4 from directly importing L1 physics modules
config :tiannara, :layer_dependencies,
  l0: [],
  l1: [:l0],
  l2: [:l0, :l1],
  l3: [:l0, :l1, :l2],
  l4: [:l0, :l1, :l2, :l3]

# Enforce via compiler plugin (custom Mix task)
# lib/mix/tasks/check.layers.ex