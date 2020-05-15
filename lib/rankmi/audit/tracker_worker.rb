require 'sidekiq'

module Rankmi
  module Audit
    class TrackerWorker
      include Sidekiq::Worker

      def perform(options = {})
        if Rankmi::Audit.instance.tracker.request_allowed?(audit_type: options['audit_type'], tenant: options['tenant'])
          api_response = Typhoeus.post(
              options['url'],
              headers: JSON.parse(options['json_encoded_headers']),
              body: options['json_encoded_body']
          )
          Rankmi::Audit.instance.tracker.validate_api_response_code(api_response)
        end

      rescue Rankmi::Audit::MissingTenant, Rankmi::Audit::UnableAuditCreation, Rankmi::Audit::InvalidTrackType
        # Prevent the worker to be retried by Sidekiq for these custom errors
      end

    end
  end
end
