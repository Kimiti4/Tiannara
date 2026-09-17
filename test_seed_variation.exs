# Quick seed variation test
IO.puts("Testing seed variation...")

:rand.seed(:exsplus, {12345, 12345, 12345})
v1 = :rand.uniform()

:rand.seed(:exsplus, {67890, 67890, 67890})
v2 = :rand.uniform()

IO.puts("Seed 12345: #{v1}")
IO.puts("Seed 67890: #{v2}")
IO.puts("Different? #{v1 != v2}")
