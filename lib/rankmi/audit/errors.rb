module Rankmi
  module Audit
    class ConnectionRefused < StandardError; end
    class InvalidTenant < StandardError; end
    class InvalidTrackType < StandardError; end
    class MissingConfiguration < StandardError; end
    class MissingTenant < StandardError; end
    class RedisConnectionRefused < StandardError; end
    class UnableAuditCreation < StandardError; end
    class UnableDatabaseConnection < StandardError; end
    class Unauthorized < StandardError; end
  end
end