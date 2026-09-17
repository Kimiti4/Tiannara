defmodule TelemetryGateway.Validator do
  @required_fields [:id, :source, :version, :timestamp, :domain]

  def valid?(event) do
    Enum.all?(@required_fields, fn field ->
      Map.has_key?(event, field) && event[field] != nil
    end)
  end

  def validate(event) do
    missing =
      Enum.reject(@required_fields, fn field ->
        Map.has_key?(event, field) && event[field] != nil
      end)

    if missing == [] do
      {:ok, event}
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end
end
