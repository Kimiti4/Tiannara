defmodule Tiannara.Meta.Hardware.EventHorizonTensorCore do
  @moduledoc """
  Bounded tensor-compute worker for the EHTC fabric.

  The HSV/event-horizon terminology is retained as an architectural metaphor.
  Computation is performed by a real backend and remains measurable and bounded.
  """
  use GenServer

  @max_queue_depth 10_000
  @default_timeout 30_000

  defstruct hsv_id: nil, queue_depth: 0, processed_count: 0, failed_count: 0

  def start_link(opts) do
    hsv_id = Keyword.fetch!(opts, :hsv_id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(hsv_id))
  end

  def submit_payload(hsv_id, payload), do: GenServer.call(via_tuple(hsv_id), {:submit, payload})
  def stats(hsv_id), do: GenServer.call(via_tuple(hsv_id), :stats)

  def compute(hsv_id, operation, payload, opts \\ []) do
    GenServer.call(via_tuple(hsv_id), {:compute, operation, payload}, Keyword.get(opts, :timeout, @default_timeout))
  catch
    :exit, reason -> {:error, {:ehtc_call_exit, reason}}
  end

  # Pure backend entry point, also useful for certification without OTP boot.
  def dispatch_for_test(tensor, components), do: dispatch(:principal_eigenvectors, {tensor, components})

  @impl true
  def init(opts) do
    {:ok, %__MODULE__{hsv_id: Keyword.fetch!(opts, :hsv_id)}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, {:ok, %{core_id: state.hsv_id, queue_depth: state.queue_depth,
      processed_count: state.processed_count, failed_count: state.failed_count,
      backend: :nx_cpu}}, state}
  end

  @impl true
  def handle_call({:submit, _payload}, _from, %{queue_depth: depth} = state)
      when depth >= @max_queue_depth, do: {:reply, {:error, :backpressure}, state}

  @impl true
  def handle_call({:submit, payload}, _from, state) do
    send(self(), {:legacy_payload, payload})
    {:reply, :accepted, %{state | queue_depth: state.queue_depth + 1}}
  end

  @impl true
  def handle_call({:compute, operation, payload}, _from, state) do
    started = System.monotonic_time(:microsecond)

    case dispatch(operation, payload) do
      {:ok, value, metadata} ->
        duration = System.monotonic_time(:microsecond) - started
        result = Map.merge(metadata, %{backend: :nx_cpu, core_id: state.hsv_id,
          operation: operation, duration_us: duration})
        {:reply, {:ok, value, result}, %{state | processed_count: state.processed_count + 1}}
      {:error, reason} ->
        {:reply, {:error, reason}, %{state | failed_count: state.failed_count + 1}}
    end
  end

  @impl true
  def handle_info({:legacy_payload, _payload}, state) do
    {:noreply, %{state | queue_depth: max(state.queue_depth - 1, 0)}}
  end

  defp dispatch(:principal_eigenvectors, {tensor, components}) do
    pca(tensor, components)
  end
  defp dispatch(:principal_eigenvectors, %{tensor: tensor, components: components}) do
    pca(tensor, components)
  end
  defp dispatch(operation, _), do: {:error, {:unsupported_operation, operation}}

  defp pca(%Nx.Tensor{} = tensor, components) when is_integer(components) and components > 0 do
    matrix = normalize_matrix(tensor)
    {samples, features} = Nx.shape(matrix)
    if samples < 2 do
      {:error, :insufficient_samples_for_covariance}
    else
      k = min(components, min(samples, features))
      mean = Nx.mean(matrix, axes: [0], keep_axes: true)
      centered = Nx.subtract(matrix, mean)
      covariance = Nx.dot(Nx.transpose(centered), centered) |> Nx.divide(samples - 1)

      try do
        {values, vectors} = Nx.LinAlg.eigh(covariance)
        pairs =
          values
          |> Nx.to_flat_list()
          |> Enum.with_index()
          |> Enum.sort_by(fn {value, _} -> value end, :desc)
          |> Enum.take(k)

        indices = Enum.map(pairs, &elem(&1, 1))
        basis =
          Enum.map(indices, fn index -> Nx.slice(vectors, [0, index], [features, 1]) end)
          |> Nx.concatenate(axis: 1)

        {:ok, basis, %{samples: samples, features: features, components: k,
          explained_variance: Enum.map(pairs, &elem(&1, 0)), mean: mean}}
      rescue
        error -> {:error, {:eigendecomposition_failed, Exception.message(error)}}
      end
    end
  end
  defp pca(_, _), do: {:error, :invalid_tensor}

  defp normalize_matrix(%Nx.Tensor{shape: shape} = tensor) do
    dims = Tuple.to_list(shape)
    features = List.last(dims)
    samples = div(Enum.reduce(dims, 1, &*/2), features)
    Nx.reshape(tensor, {samples, features})
  end

  defp via_tuple(hsv_id), do: {:via, Registry, {Tiannara.HardwareRegistry, hsv_id}}
end
