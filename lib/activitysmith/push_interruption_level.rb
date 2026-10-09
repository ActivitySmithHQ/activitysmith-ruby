# frozen_string_literal: true

module ActivitySmith
  module PushInterruptionLevel
    PASSIVE = "passive"
    ACTIVE = "active"
    TIME_SENSITIVE = "time-sensitive"
    VALUES = [PASSIVE, ACTIVE, TIME_SENSITIVE].freeze
  end
end
