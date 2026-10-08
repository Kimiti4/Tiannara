ExUnit.start(trace: true, seed: 0, timeout: 30_000, max_cases: 4, assert_receive_timeout: 5_000)

Application.put_env(:tiannara, :test_mode, true)

test_data_path = Application.get_env(:tiannara, :dets_base_path, "./test_data/dets")
File.rm_rf!(test_data_path)
File.mkdir_p!(test_data_path)

ExUnit.after_suite(fn _results ->
  File.rm_rf!(test_data_path)
end)
