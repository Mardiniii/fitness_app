# One row of the practitioner's roster: has this person actually been training?
#
# Every number here comes from completed sessions. There is no composite
# "engagement score" -- a made-up number nobody can check is worse than no
# number, because the practitioner cannot tell when it is lying.
class ClientSummary
  def self.for(clients)
    Array(clients).map { |client| new(client) }
  end

  def initialize(client)
    @client = client
  end

  attr_reader :client

  def assignment
    @assignment ||= client.program_assignments.current.order(starts_on: :desc).first
  end

  def program = assignment&.program

  def sessions_done
    @sessions_done ||= assignment ? assignment.sessions.where(status: "completed").count : 0
  end

  def sessions_total
    @sessions_total ||=
      if assignment
        ProgramDay.where(program_week: assignment.program_version.program_weeks).count
      else
        0
      end
  end

  def completion_pct
    return 0 if sessions_total.zero?

    (sessions_done * 100 / sessions_total)
  end

  # Consecutive weeks, counting back from this one, with at least one completed
  # session. The current week does not break a streak until it ends -- Monday
  # morning should not read as "you fell off".
  def streak
    return 0 if completed_weeks.empty?

    week = Date.current.beginning_of_week
    week -= 1.week unless completed_weeks.include?(week)

    count = 0
    while completed_weeks.include?(week)
      count += 1
      week -= 1.week
    end
    count
  end

  def last_session_at
    @last_session_at ||= assignment&.sessions&.where(status: "completed")&.maximum(:completed_at)
  end

  def days_since_last = last_session_at && (Date.current - last_session_at.to_date).to_i

  # The one judgement call on this screen, and it is a threshold rather than a
  # score: ten days without a session is worth a look.
  def stale? = days_since_last.nil? || days_since_last >= 10

  private

  def completed_weeks
    @completed_weeks ||=
      if assignment.nil?
        Set.new
      else
        assignment.sessions.where(status: "completed")
                  .filter_map { |session| session.completed_at&.to_date&.beginning_of_week }
                  .to_set
      end
  end
end
