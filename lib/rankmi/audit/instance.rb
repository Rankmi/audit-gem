module Rankmi
  module Audit
    class Instance
      # See Rankmi::Audit::Configuration
      attr_accessor :configuration

      # See Rankmi::Audit::Tracker
      attr_writer :tracker

      def initialize(config: nil)
        self.configuration = config || Rankmi::Audit::Configuration.new
      end

      # Call this method to modify defaults of Rankmi::Audit from Rails environments files.
      #
      # @example
      #   Rankmi::Audit.configure do |config|
      #     config.api_endpoint = 'http://...'
      #   end
      def configure
        yield(configuration) if block_given?
        @tracker = Tracker.new(configuration)
      end

      # The tracker object is responsible for sending data to the audit API.
      def tracker
        @tracker ||= Tracker.new(configuration)
      end

      # Forward action tracking to Tracker handler
      def track_action(tenant:, audit_hash:)
        tracker.track(audit_type: 'action', tenant: tenant, audit_hash: audit_hash)
      end

      # Forward change tracking to Tracker handler
      def track_change(tenant:, audit_hash:)
        tracker.track(audit_type: 'change', tenant: tenant, audit_hash: audit_hash)
      end

    end
  end
end
