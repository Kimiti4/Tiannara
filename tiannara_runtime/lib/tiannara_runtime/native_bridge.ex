defmodule TiannaraRuntime.NativeBridge do
  @moduledoc """
  Single, configuration-driven boundary to native (NIF) accelerators.

  Native accelerators are declared in application configuration instead of
  being hardcoded at each call site:

      config :tiannara_runtime, :native_accelerators,
        rrm_native_jit: [path: "priv/native/rrm_native_jit"]

      config :tiannara_runtime, :native_accelerator_app, :tiannara_runtime

  Paths are resolved against the *running* OTP application, so a bridge never
  assumes a per-phase application that does not exist. When an accelerator is
  absent the bridge fails closed with a typed reason instead of raising
  `UndefinedFunctionError`.

  Every per-phase `NativeBridge` module delegates here, so there is exactly
  one implementation of native loading and one place where the accelerator
  inventory is configured.
  """

  @config_key :native_accelerators
  @app_config_key :native_accelerator_app
  @default_app :tiannara_runtime

  @type accelerator :: atom()
  @type status :: :available | :not_configured | :missing

  @doc "Returns the configured accelerator inventory as a map."
  @spec config() :: %{accelerator() => keyword()}
  def config do
    Application.get_env(@default_app, @config_key, %{})
  end

  @doc "The OTP application that owns the native `priv/` directory."
  @spec owner_app() :: atom()
  def owner_app do
    Application.get_env(@default_app, @app_config_key, @default_app)
  end

  @doc """
  Reports whether an accelerator is usable.

  * `:not_configured` — the accelerator is absent from configuration.
  * `:missing` — configured, but the native artifact is not present.
  * `:not_loaded` — configured, the artifact is present, but the NIF is not loaded.
  * `:available` — the NIF library is loaded and callable.
  """
  @spec status(accelerator()) :: status()
  def status(accelerator) when is_atom(accelerator) do
    case config()[accelerator] do
      nil ->
        :not_configured

      opts ->
        module = Keyword.get(opts, :module, accelerator)

        if Code.ensure_loaded?(module) do
          :available
        else
          case native_path(accelerator) do
            {:ok, path} -> if File.exists?(path), do: :not_loaded, else: :missing
            {:error, _} -> :missing
          end
        end
    end
  end

  @doc """
  Loads the native library for an accelerator.

  Returns `:ok` when the library is loaded, `{:error, reason}` otherwise. A
  missing library is reported, never raised.
  """
  @spec load(accelerator()) :: :ok | {:error, term()}
  def load(accelerator) when is_atom(accelerator) do
    module = module_for(accelerator)

    if Code.ensure_loaded?(module) do
      :ok
    else
      case native_path(accelerator) do
        {:ok, path} ->
          if File.exists?(path) do
            case :erlang.load_nif(path, 0) do
              :ok -> :ok
              {:error, reason} -> {:error, {:nif_load_failed, reason}}
            end
          else
            {:error, {:nif_missing, path}}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  rescue
    error -> {:error, {:nif_load_failed, Exception.message(error)}}
  end

  @doc """
  Calls a native function through an accelerator.

  Fails closed with `{:error, :nif_unavailable}` when the accelerator is not
  configured, not loaded, or does not export the function.
  """
  @spec call(accelerator(), atom(), list()) :: {:ok, term()} | {:error, term()}
  def call(accelerator, function, args) when is_atom(accelerator) and is_atom(function) do
    module = module_for(accelerator)
    arity = length(args)

    cond do
      is_nil(config()[accelerator]) ->
        {:error, :nif_not_configured}

      not Code.ensure_loaded?(module) ->
        {:error, :nif_unavailable}

      not function_exported?(module, function, arity) ->
        {:error, :nif_function_unavailable}

      true ->
        try do
          {:ok, apply(module, function, args)}
        rescue
          error -> {:error, {:nif_call_failed, Exception.message(error)}}
        catch
          kind, reason -> {:error, {:nif_call_failed, kind, reason}}
        end
    end
  end

  @doc "Resolves the on-disk path of an accelerator's native library."
  @spec native_path(accelerator()) :: {:ok, String.t()} | {:error, term()}
  def native_path(accelerator) do
    case config()[accelerator] do
      nil ->
        {:error, :accelerator_not_configured}

      opts ->
        rel = Keyword.get(opts, :path)
        app = Keyword.get(opts, :app, owner_app())

        if is_nil(rel) do
          {:error, :accelerator_path_missing}
        else
          case :code.priv_dir(app) do
            {:error, :bad_name} ->
              {:error, {:accelerator_app_not_loaded, app}}

            priv_dir ->
              {:ok, Path.join(List.to_string(priv_dir), rel)}
          end
        end
    end
  end

  defp module_for(accelerator) do
    case config()[accelerator] do
      nil -> accelerator
      opts -> Keyword.get(opts, :module, accelerator)
    end
  end
end
