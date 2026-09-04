result = Tiannara.CRAV.ChallengeRunner.run_all()
output = inspect(result, pretty: true, limit: :infinity)
File.write!("data/challenge_output.txt", output)
IO.puts("Written to data/challenge_output.txt")
