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
      #   Only configuration @allowed_tenants response values are permitted.
      def request_allowed?(audit_type: , tenant:)
        return error_response("Rankmi::Audit configuration is not valid: #{ configuration.error_messages }", MissingConfiguration) unless configuration.valid?
        return error_response("Unknown track type #{audit_type}", InvalidTrackType) unless %w(action change).include?(audit_type)
        return error_response("Invalid tenant: #{ tenant }", InvalidTenant) unless configuration.allowed_tenants.call.include?(tenant)
        true
      end

      # Validates a Typhoeus response code and return true if it is a HTTP success status.
      #
      # If configuration @fail_silently is false, then an Error could be raised
      #   if something goes wrong, otherwise a boolean will be returned.
      #
      # @param [Typhoeus::Response] typhoeus_response returned by Rankmi audit API
      def validate_api_response_code(typhoeus_response)
        return error_response('An error ocurred in Rankmi audits api that prevents the audit to be created', UnableAuditCreation) if typhoeus_response.code == 400
        return error_response('Rankmi::Audit api_key and/or api_secret provided are not valid', Unauthorized) if typhoeus_response.code == 401
        return error_response('No authorization headers provided', MissingConfiguration) if typhoeus_response.code == 403
        return error_response('No tenant provided', MissingTenant) if typhoeus_response.code == 422
        return error_response('Unable to connect to audit database', UnableDatabaseConnection) if typhoeus_response.code == 503
        true
      end

      # Send a request to audit API to track a new change or action.
      #
      # Depending on sidekiq configuration provided to the gem, this method will
      #   enqueue the API call in a worker, or will perform the API call synchronously.
      #
      # @param [String] audit_type define if the audit to track will be an action or a change.
      #   Allowed values are 'action' or 'change', otherwise the request will not be fired.
      # @param [String] tenant is the mongoDB database name in with the audit will be saved.
      #   Typically in Rankmi, the value of this param is the associated enterprise token.
      # @param [Hash] audit_hash is the data that will be saved in Rankmi audit database.
      #
      # @return [Boolean|Error]
      def track(audit_type:, tenant:, audit_hash:)
        if configuration&.use_sidekiq
          track_later(audit_type: audit_type, tenant: tenant, audit_hash: audit_hash)
        else
          track_now(audit_type: audit_type, tenant: tenant, audit_hash: audit_hash)
        end
      end

      private

      def track_now(audit_type:, tenant:, audit_hash:)
        if request_allowed?(audit_type: audit_type, tenant: tenant)
          api_response = Typhoeus.post(
              "#{ configuration&.api_endpoint }/v1/#{ tenant }/#{audit_type}",
              headers: required_audit_api_headers,
              body: audit_hash.to_json
          )
          validate_api_response_code(api_response)
        end
      end

      def track_later(audit_type:, tenant:, audit_hash:)
        if ( Sidekiq::Testing.disabled? rescue true ) and not ( Sidekiq.redis(&:info) rescue false )
          return error_response('Unable to connect to redis. Check Sidekiq server configuration or set use_sidekiq configuration as false.', RedisConnectionRefused)
        end

        Rankmi::Audit::TrackerWorker.set(queue: configuration.sidekiq_queue).perform_async(
            {
                audit_type: audit_type,
                tenant: tenant,
                url: "#{ configuration&.api_endpoint }/v1/#{ tenant }/#{audit_type}",
                json_encoded_headers: required_audit_api_headers.to_json,
                json_encoded_body: audit_hash.to_json
            }
        )
      end

      def required_audit_api_headers
        {
            'Content-Type' => CONTENT_TYPE,
            'audit-auth-key' => configuration.api_key,
            'audit-auth-secret' => configuration.api_secret
        }
      end

      # Raise a given error if configuration fail_silently is false.
      # Otherwise just return false.
      def error_response(error_message, error_class = StandardError)
        raise(error_class, error_message) unless configuration.fail_silently
        false
      end

    end
  end
end