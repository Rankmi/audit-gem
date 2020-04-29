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

      # Array that store all allowed tenant values to send to the audit API.
      # If a tenant it's not in this array, the audit will not been sent.
      attr_accessor :allowed_tenants

      # Errors object - an Array that contains error messages.
      attr_reader :errors

      def initialize
        @fail_silently = true
        @allowed_tenants = []
      end

      # Validate all required configuration attributes, fills @errors attribute if something
      # goes wrong and returns a boolean.
      def valid?
        @errors = []

        @errors << 'No api_endpoint specified' if not defined?(@api_endpoint) or @api_endpoint.nil?
        @errors << 'Invalid api_endpoint. It must be a valid URL' if not defined?(@api_endpoint) or not ( URI.parse(@api_endpoint).kind_of?(URI::HTTP) rescue false)
        @errors << 'No api_key specified' if not defined?(@api_key) or @api_key.nil?
        @errors << 'No api_secret specified' if not defined?(@api_secret) or @api_secret.nil?

        return @errors.count == 0
      end

      def error_messages
        if @errors.count > 1
          @errors = [errors[0]] + errors[1..-1].map(&:downcase) # fix case of all but first
          errors.join(", ")
        else
          ''
        end
      end

    end
  end
end
