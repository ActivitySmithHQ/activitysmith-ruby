# frozen_string_literal: true

module ActivitySmith
  class LiveActivities
    def initialize(api)
      @api = api
    end

    def start(request, opts = {})
      @api.start_live_activity(request, opts)
    end

    def update(request, opts = {})
      @api.update_live_activity(request, opts)
    end

    def end(request, opts = {})
      @api.end_live_activity(request, opts)
    end

    # Backward-compatible aliases.
    def start_live_activity(live_activity_start_request, opts = {})
      @api.start_live_activity(live_activity_start_request, opts)
    end

    def update_live_activity(live_activity_update_request, opts = {})
      @api.update_live_activity(live_activity_update_request, opts)
    end

    def end_live_activity(live_activity_end_request, opts = {})
      @api.end_live_activity(live_activity_end_request, opts)
    end

    def method_missing(name, *args, &block)
      return @api.public_send(name, *args, &block) if @api.respond_to?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      @api.respond_to?(name, include_private) || super
    end
  end
end
