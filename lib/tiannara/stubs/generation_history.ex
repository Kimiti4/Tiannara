defmodule GenerationHistory do
  use Tiannara.Stub, subsystem: :os, phase: "Omega+", priority: :high

  def new(opts \\ %{}) do
    stub_result(:new, [opts], TiannaraOS.Kernel.GenerationHistory.new(opts))
  end

  def calculate_cai(sample) do
    stub_result(:calculate_cai, [sample], 0.0)
  end

  def append_to_file(history, file_path) do
    stub_result(:append_to_file, [history, file_path], :ok)
  end
end
