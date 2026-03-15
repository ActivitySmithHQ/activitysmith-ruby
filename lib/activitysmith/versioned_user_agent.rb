# frozen_string_literal: true

module ActivitySmith
  module VersionedUserAgent
    def self.value
      "activitysmith-ruby/#{ActivitySmith::VERSION}"
    end
  end
end
