require 'json'
require 'typhoeus'

module Rankmi
  module Audit
    class Tracker
      CONTENT_TYPE = 'application/json'.freeze

      attr_accessor :configuration

      def initialize(configuration)
        @configuration = configuration
      end

      # Validates if the request could be fired.
      #
      # If configuration @fail_silently is false, then an Error could be raised
      #   if something goes wrong, otherwise a boolean will be returned.
      #
      # @param [String] audit_type is the audit API url action that will be tracked.
      #   Permitted audit_type values are 'action' or 'change'.
      # @param [String] tenant is the mongoDB database name in with the audit will be saved.
      #   Only configuration @allowed_tenants values are permitted.
      def request_allowed?(audit_type: , tenant:)
        return error_response("Rankmi::Audit configuration is not valid: #{ configuration.error_messages }") unless configuration.valid?
        return error_response("Unknown track type #{audit_type}") unless %w(action change).include?(audit_type)
        return error_response("Invalid tenant: #{ tenant }") unless configuration.allowed_tenants.include?(tenant)
        true
      end

      # Send a request to audit API to track a new change or action.
      #
      # @param [String] audit_type define if the audit to track will be an action or a change.
      #   Allowed values are 'action' or 'change', otherwise the request will not be fired.
      # @param [String] tenant is the mongoDB database name in with the audit will be saved.
      #   Typically in Rankmi, the value of this param is the associated enterprise token.
      # @param [Hash] audit_hash is the data that will be saved in Rankmi audit database.
      #
      # @return [Boolean|Error]
      def track(audit_type:, tenant:, audit_hash:)
        if request_allowed?(audit_type: audit_type, tenant: tenant)
          Typhoeus.post(
              "#{ configuration&.api_endpoint }/v1/#{ tenant }/#{audit_type}",
              headers: required_audit_api_headers,
              body: audit_hash.to_json
          )

          # TODO: handle Rankmi audit http response codes.
        end
      end

      private

      def required_audit_api_headers
        {
            'Content-Type' => CONTENT_TYPE,
            'audit-auth-key' => configuration.api_key,
            'audit-auth-token' => configuration.api_secret
        }
      end

      # Raise a given error if configuration fail_silently is false.
      # Otherwise just return false.
      def error_response(error_message)
        raise(StandardError, error_message) unless configuration.fail_silently
        false
      end

    end
  end
end