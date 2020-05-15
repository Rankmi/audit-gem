module Rankmi
  module Audit
    class Configuration
      # Required. URL that serves Rankmi audit API.
      # It could be a URL from localhost or some GCP function endpoint.
      #
      # @example: "http://localhost:8090"
      attr_accessor :api_endpoint

      # Required. Key defined in the environment of the audit API.
      # This will be validated by the API on every request and will throw an error if the values aren't equal.
      attr_accessor :api_key

      # Required. Secret key defined in the environment of the audit API.
      # This will be validated by the API on every request and will throw an error if the values aren't equal.
      attr_accessor :api_secret

      # Boolean that defines if the gem will throw an error when something goes wrong.
      # True by default. It's recommended to set this attribute false for production environments.
      attr_accessor :fail_silently

      # A lambda that store a method to get an array with all allowed tenant values to send to the audit API.
      # If a tenant it's not in this returned array, the audit will not been sent.
      attr_accessor :allowed_tenants

      # Errors object - an Array that contains error messages.
      attr_reader :errors

      # Boolean that defines if the tracker will be performed asynchronously with a Sidekiq worker.
      # False by default. It's recommended to set this attribute true for production environments.
      attr_accessor :use_sidekiq

      # Defines the name of the queue that will be used when tracker_worker is performed asynchronously.
      # By default, all track workers will be enqueued in 'tracker'.
      attr_accessor :sidekiq_queue

      def initialize
        @fail_silently = true
        @allowed_tenants = -> { [] }
        @use_sidekiq = false
        @sidekiq_queue = :tracker
      end

      # Validate all required configuration attributes, fills @errors attribute if something
      # goes wrong and returns a boolean.
      def valid?
        @errors = []

        @errors << 'No api_endpoint specified' if not defined?(@api_endpoint) or @api_endpoint.nil?
        @errors << 'Invalid api_endpoint, it must be a valid URL' if not defined?(@api_endpoint) or not ( URI.parse(@api_endpoint).kind_of?(URI::HTTP) rescue false)
        @errors << 'No api_key specified' if not defined?(@api_key) or @api_key.nil?
        @errors << 'No api_secret specified' if not defined?(@api_secret) or @api_secret.nil?

        @errors.count.zero?
      end

      def error_messages
        return '' if @errors.count.zero? 
        @errors = [errors[0]] + errors[1..-1].map(&:downcase) # fix case of all but first
        errors.join(", ")
      end

    end
  end
end
