require 'rankmi/audit/version'
require 'rankmi/audit/errors'
require 'rankmi/audit/configuration'
require 'rankmi/audit/tracker'
require 'rankmi/audit/instance'

module Rankmi
  module Audit
    class << self
      extend Forwardable

      def instance
        @instance ||= Rankmi::Audit::Instance.new
      end

      def_delegators :instance, :configure, :configuration, :track_action, :track_change
    end
  end
end
