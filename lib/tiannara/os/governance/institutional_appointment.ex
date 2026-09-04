defmodule TiannaraOS.Governance.InstitutionalAppointment do
  @moduledoc """
  InstitutionalAppointment - Records appointment and removal of institutional members.

  Appointments are constitutional events that must be recorded immutably in the
  Governance Ledger. Each appointment has explicit authority boundaries, term limits,
  and can only be executed by institutions with `:can_appoint` or `:can_remove` capabilities.

  ## Appointment Lifecycle

  1. **Nomination** - Candidate proposed by authorized institution
  2. **Review** - Review Board assesses candidate qualifications
  3. **Ratification** - Governance Council votes on appointment
  4. **Activation** - Member added to institution with role assignment
  5. **Term Monitoring** - Observatory tracks term expiration
  6. **Renewal/Removal** - Process repeats at term end

  ## Conservation Law

  No appointment ever disappears. All appointments and removals are permanently
  recorded in the Governance Ledger for replay and archaeology.

  ## Fields

  - `appointment_id` - Unique identifier
  - `member_id` - Appointed individual/entity identifier
  - `institution_id` - Target institution
  - `role_id` - Constitutional role assigned
  - `appointed_by` - Institution that made the appointment
  - `appointment_date` - When appointment became active
  - `term_start` - Term start date
  - `term_end` - Term end date (nil for lifetime appointments)
  - `status` - :active, :expired, :removed, :resigned
  - `removal_reason` - Reason if removed (nil if active/expired)
  - `removed_by` - Institution that removed (if applicable)
  - `removal_date` - When removal occurred (if applicable)
  """

  defstruct [
    :appointment_id,
    :member_id,
    :institution_id,
    :role_id,
    :appointed_by,
    :appointment_date,
    :term_start,
    :term_end,
    :status,
    :removal_reason,
    :removed_by,
    :removal_date,
    :metadata,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          appointment_id: String.t(),
          member_id: String.t(),
          institution_id: String.t(),
          role_id: String.t(),
          appointed_by: String.t(),
          appointment_date: DateTime.t(),
          term_start: DateTime.t(),
          term_end: DateTime.t() | nil,
          status: atom(),
          removal_reason: String.t() | nil,
          removed_by: String.t() | nil,
          removal_date: DateTime.t() | nil,
          metadata: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
  Create new appointment record.

  Requires authorization from institution with `:can_appoint` capability.
  """
  @spec create_appointment(map()) :: {:ok, t()} | {:error, term()}
  def create_appointment(attrs) do
    now = DateTime.utc_now()

    appointment = %__MODULE__{
      appointment_id: attrs[:appointment_id] || generate_id(),
      member_id: attrs[:member_id],
      institution_id: attrs[:institution_id],
      role_id: attrs[:role_id],
      appointed_by: attrs[:appointed_by],
      appointment_date: attrs[:appointment_date] || now,
      term_start: attrs[:term_start] || now,
      term_end: attrs[:term_end],
      status: :active,
      removal_reason: nil,
      removed_by: nil,
      removal_date: nil,
      metadata: attrs[:metadata] || %{},
      created_at: now,
      updated_at: now
    }

    # TODO: Validate role exists and is compatible with institution
    # TODO: Verify appointing institution has :can_appoint capability
    # TODO: Check quorum requirements for appointment decision
    # TODO: Record in Governance Ledger

    {:ok, appointment}
  end

  @doc """
  Remove member from institution.

  Requires authorization from institution with `:can_remove` capability.
  """
  @spec remove_member(t(), String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def remove_member(%__MODULE__{status: :active} = appointment, removed_by, reason) do
    now = DateTime.utc_now()

    updated = %{
      appointment
      | status: :removed,
        removal_reason: reason,
        removed_by: removed_by,
        removal_date: now,
        updated_at: now
    }

    # TODO: Verify removing institution has :can_remove capability
    # TODO: Check quorum requirements for removal decision
    # TODO: Record removal in Governance Ledger

    {:ok, updated}
  end

  @doc """
  Expire appointment when term ends.
  """
  @spec expire_appointment(t()) :: {:ok, t()} | {:error, term()}
  def expire_appointment(%__MODULE__{status: :active} = appointment) do
    now = DateTime.utc_now()

    updated = %{
      appointment
      | status: :expired,
        updated_at: now
    }

    {:ok, updated}
  end

  @doc """
  Renew appointment for new term.
  """
  @spec renew_appointment(t(), DateTime.t(), non_neg_integer()) :: {:ok, t()} | {:error, term()}
  def renew_appointment(
        %__MODULE__{status: status} = appointment,
        renewal_date,
        term_months
      )
      when status in [:active, :expired] do
    term_end =
      if term_months > 0 do
        DateTime.add(renewal_date, term_months * 30, :day)
      else
        nil
      end

    updated = %{
      appointment
      | status: :active,
        term_start: renewal_date,
        term_end: term_end,
        removal_reason: nil,
        removed_by: nil,
        removal_date: nil,
        updated_at: DateTime.utc_now()
    }

    # TODO: Verify renewing institution has :can_appoint capability
    # TODO: Record renewal in Governance Ledger

    {:ok, updated}
  end

  @doc """
  Check if appointment is currently active.
  """
  @spec active?(t()) :: boolean()
  def active?(%__MODULE__{status: :active}), do: true
  def active?(_), do: false

  @doc """
  Check if appointment term has expired.
  """
  @spec term_expired?(t()) :: boolean()
  def term_expired?(%__MODULE__{term_end: nil, status: :active}), do: false
  def term_expired?(%__MODULE__{status: s}) when s != :active, do: false

  def term_expired?(%__MODULE__{term_end: term_end}) do
    DateTime.compare(DateTime.utc_now(), term_end) == :gt
  end

  @doc """
  Get appointment duration in days.
  """
  @spec duration_days(t()) :: integer()
  def duration_days(%__MODULE__{term_start: start, term_end: nil}) do
    DateTime.diff(DateTime.utc_now(), start, :day)
  end

  def duration_days(%__MODULE__{term_start: start, term_end: end_date}) do
    DateTime.diff(end_date, start, :day)
  end

  @doc """
  Get remaining term days (negative if expired).
  """
  @spec remaining_days(t()) :: integer()
  def remaining_days(%__MODULE__{term_end: nil}), do: :infinity
  def remaining_days(%__MODULE__{status: s}) when s != :active, do: 0

  def remaining_days(%__MODULE__{term_end: term_end}) do
    DateTime.diff(term_end, DateTime.utc_now(), :day)
  end

  @doc """
  Generate unique appointment ID.
  """
  @spec generate_id() :: String.t()
  def generate_id() do
    "appt-#{:erlang.unique_integer([:positive, :monotonic])}-#{System.system_time(:millisecond)}"
  end

  @doc """
  Convert appointment to governance ledger event.
  """
  @spec to_ledger_event(t()) :: map()
  def to_ledger_event(%__MODULE__{} = appointment) do
    %{
      event_type: :appointment_created,
      appointment_id: appointment.appointment_id,
      member_id: appointment.member_id,
      institution_id: appointment.institution_id,
      role_id: appointment.role_id,
      appointed_by: appointment.appointed_by,
      timestamp: appointment.appointment_date,
      metadata: appointment.metadata
    }
  end

  @doc """
  Convert removal to governance ledger event.
  """
  @spec removal_to_ledger_event(t()) :: map() | nil
  def removal_to_ledger_event(%__MODULE__{status: :removed} = appointment) do
    %{
      event_type: :appointment_removed,
      appointment_id: appointment.appointment_id,
      member_id: appointment.member_id,
      institution_id: appointment.institution_id,
      removed_by: appointment.removed_by,
      removal_reason: appointment.removal_reason,
      timestamp: appointment.removal_date,
      metadata: appointment.metadata
    }
  end

  def removal_to_ledger_event(_), do: nil
end
