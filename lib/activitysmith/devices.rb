# frozen_string_literal: true

module ActivitySmith
  class Devices
    def initialize(api)
      @api = api
    end

    # Lists the iPhones and iPads paired to the account, active devices first.
    def list(limit: nil, offset: nil, include_inactive: nil, **opts)
      query = { limit: limit, offset: offset, include_inactive: include_inactive }.compact
      @api.list_account_devices(opts.merge(query))
    end

    # Generated-style alias.
    def list_account_devices(opts = {})
      @api.list_account_devices(opts)
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
