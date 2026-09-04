defmodule Tiannara.Soak.TimeAccounting do
  @moduledoc """
  Distinguishes wall-clock runtime from validated soak duration so Tiannara
  never claims 72h of continuous validation when there was a restart.

      validated_seconds   — what checkpoints prove (counts toward the 72h)
      wall_clock_seconds  — real time since the run's first start
      unvalidated_seconds — wall − validated (crash + restart + lost work)

  Invariant: validated + unvalidated == wall_clock, and validated ≤ wall_clock.
  A violation is flagged, never smoothed over.

  Constitutional basis: "Never optimize for appearing correct. Optimize for
  being correct." / "Uncertainty should never be hidden."
  """

  defstruct [
    :first_started_at,
    :validated_seconds,
    :wall_clock_seconds,
    :unvalidated_seconds,
    :restarted?,
    :consistent?
  ]

  def compute(now_s, first_started_s, validated_seconds, opts \\ [])
      when is_integer(now_s) and is_integer(first_started_s) do
    wall = now_s - first_started_s
    unvalidated = max(wall - validated_seconds, 0)

    %__MODULE__{
      first_started_at: first_started_s,
      validated_seconds: validated_seconds,
      wall_clock_seconds: wall,
      unvalidated_seconds: unvalidated,
      restarted?: Keyword.get(opts, :restarted?, false),
      consistent?: validated_seconds <= wall
    }
  end

  def reconciled?(%__MODULE__{} = t) do
    t.consistent? and
      t.validated_seconds + t.unvalidated_seconds == t.wall_clock_seconds
  end

  def report(%__MODULE__{} = t) do
    """
    Validated soak time:   #{hms(t.validated_seconds)}
    Wall-clock elapsed:    #{hms(t.wall_clock_seconds)}
    Unvalidated gap:       #{hms(t.unvalidated_seconds)}
    Restarted:             #{t.restarted?}
    Books reconciled:      #{reconciled?(t)}
    """
  end

  defp hms(total) do
    h = div(total, 3600)
    m = div(rem(total, 3600), 60)
    s = rem(total, 60)
    "#{h}h #{pad(m)}m #{pad(s)}s"
  end

  defp pad(n), do: String.pad_leading(Integer.to_string(n), 2, "0")
end
