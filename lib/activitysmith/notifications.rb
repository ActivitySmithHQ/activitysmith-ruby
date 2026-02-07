# frozen_string_literal: true

module ActivitySmith
  class Notifications
    def initialize(api)
      @api = api
    end

    def send(request, opts = {})
      @api.send_push_notification(request, opts)
    end

    # Backward-compatible alias.
    def send_push_notification(push_notification_request, opts = {})
      @api.send_push_notification(push_notification_request, opts)
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
