require "test_helper"

class Rankmi::AuditTest < Minitest::Test

  def setup
    super
    ::Rankmi::Audit.instance.configuration = ::Rankmi::Audit::Configuration.new
  end

  def test_it_has_a_version_number
    refute_nil Rankmi::Audit::VERSION
  end

  def test_it_does_have_default_configuration_values_and_respond_to_forwarded_methods
    assert_respond_to Rankmi::Audit, :configuration
    assert_respond_to Rankmi::Audit, :configure
    assert_respond_to Rankmi::Audit, :instance
    assert_respond_to Rankmi::Audit, :track_action
    assert_respond_to Rankmi::Audit, :track_change

    assert_empty Rankmi::Audit.configuration.allowed_tenants.call
    assert Rankmi::Audit.configuration.fail_silently
  end

  def test_that_it_allows_custom_configuration
    Rankmi::Audit.configure do |config|
      config.api_endpoint = 'http://localhost:8090'
      config.api_key = 'test_key'
      config.api_secret = 'test_secret'
      config.fail_silently = false
      config.allowed_tenants = -> { %w(foo bar) }
    end

    assert_equal 'http://localhost:8090', ::Rankmi::Audit.configuration.api_endpoint
    assert_equal 'test_key', ::Rankmi::Audit.configuration.api_key
    assert_equal 'test_secret', ::Rankmi::Audit.configuration.api_secret
    refute_empty ::Rankmi::Audit::configuration.allowed_tenants.call
    refute ::Rankmi::Audit.configuration.fail_silently
  end

  def test_that_it_allows_to_change_modify_tenants_after_setup_configuration
    ::Rankmi::Audit.configure do |config|
      config.allowed_tenants = -> { %w(foo bar) }
    end
    assert_equal %w(foo bar), ::Rankmi::Audit::configuration.allowed_tenants.call

    ::Rankmi::Audit.configuration.allowed_tenants = -> { %w(foo bar baz) }
    assert_equal %w(foo bar baz), ::Rankmi::Audit::configuration.allowed_tenants.call
  end

  def test_it_must_validate_configuration_attributes
    refute ::Rankmi::Audit.configuration.valid?
    assert ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_endpoint specified')
    assert ::Rankmi::Audit.configuration.error_messages.downcase.include?('invalid api_endpoint, it must be a valid url')
    assert ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_key specified')
    assert ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_secret specified')

    ::Rankmi::Audit.configure do |config|
      config.api_endpoint = 'Some invalid URL'
    end
    refute ::Rankmi::Audit.configuration.valid?
    assert ::Rankmi::Audit.configuration.error_messages.downcase.include?('invalid api_endpoint, it must be a valid url')
    refute ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_endpoint specified')
    assert ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_key specified')
    assert ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_secret specified')

    ::Rankmi::Audit.configure do |config|
      config.api_endpoint = 'http://localhost:8090'
      config.api_key = 'SomeKey'
      config.api_secret = 'SomeSecret'
    end
    assert ::Rankmi::Audit.configuration.valid?
    refute ::Rankmi::Audit.configuration.error_messages.downcase.include?('invalid api_endpoint. it must be a valid url')
    refute ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_endpoint specified')
    refute ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_key specified')
    refute ::Rankmi::Audit.configuration.error_messages.downcase.include?('no api_secret specified')
  end

  def test_it_must_fail_silently_if_configuration_specifies_that
    ::Rankmi::Audit.configure do |config|
      config.fail_silently = true
    end

    assert_nil ::Rankmi::Audit.track_action(tenant: 'some-tenant', audit_hash: {})
  end

  def test_it_must_raise_errors_if_configuration_specifies_that
    ::Rankmi::Audit.configure do |config|
      config.fail_silently = false
    end

    assert_raises Rankmi::Audit::MissingConfiguration do
      ::Rankmi::Audit.track_action(tenant: 'some-tenant', audit_hash: {})
    end
  end

  def test_it_must_validate_allowed_tenants
    ::Rankmi::Audit.configure do |config|
      config.fail_silently = true
    end
    refute ::Rankmi::Audit.instance.tracker.request_allowed?(audit_type: 'action', tenant: 'some-tenant')

    ::Rankmi::Audit.configure do |config|
      config.api_endpoint = 'http://localhost:8090'
      config.api_key = 'some-api-key'
      config.api_secret = 'some-api-secret'
      config.fail_silently = false
      config.allowed_tenants = -> { ['some-valid-tenant'] }
    end
    assert_raises Rankmi::Audit::InvalidTenant do
      ::Rankmi::Audit.instance.tracker.request_allowed?(audit_type: 'action', tenant: 'some-invalid-tenant')
    end
    assert ::Rankmi::Audit.instance.tracker.request_allowed?(audit_type: 'action', tenant: 'some-valid-tenant')

    ::Rankmi::Audit.configuration.allowed_tenants = -> { %w(foo bar) }
    assert ::Rankmi::Audit.instance.tracker.request_allowed?(audit_type: 'action', tenant: 'foo')
    assert_raises Rankmi::Audit::InvalidTenant do
      ::Rankmi::Audit.instance.tracker.request_allowed?(audit_type: 'action', tenant: 'some-valid-tenant')
    end
  end

  def test_it_must_raise_errors_or_false_with_certain_http_status_responses
    ::Rankmi::Audit.configure do |config|
      config.fail_silently = false
    end

    mock_api_response_201 = Typhoeus::Response.new(code: 201)
    mock_api_response_400 = Typhoeus::Response.new(code: 400)
    mock_api_response_401 = Typhoeus::Response.new(code: 401)
    mock_api_response_403 = Typhoeus::Response.new(code: 403)
    mock_api_response_422 = Typhoeus::Response.new(code: 422)
    mock_api_response_503 = Typhoeus::Response.new(code: 503)

    assert_raises Rankmi::Audit::UnableAuditCreation do
      ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_400)
    end
    assert_raises Rankmi::Audit::Unauthorized do
      ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_401)
    end
    assert_raises Rankmi::Audit::MissingConfiguration do
      ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_403)
    end
    assert_raises Rankmi::Audit::MissingTenant do
      ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_422)
    end
    assert_raises Rankmi::Audit::UnableDatabaseConnection do
      ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_503)
    end
    assert ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_201)

    ::Rankmi::Audit.configure do |config|
      config.fail_silently = true
    end
    refute ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_400)
    refute ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_401)
    refute ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_403)
    refute ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_422)
    refute ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_503)
    assert ::Rankmi::Audit.instance.tracker.validate_api_response_code(mock_api_response_201)
  end

  def test_it_must_have_sidekiq_configuration_usage_disabled_by_default
    refute Rankmi::Audit.configuration.use_sidekiq
  end

  def test_it_must_enqueue_when_sidekiq_configuration_is_enabled
    ::Rankmi::Audit.configure do |config|
      config.api_endpoint = 'http://localhost:8090'
      config.api_key = 'SomeKey'
      config.api_secret = 'SomeSecret'
      config.use_sidekiq = true
      config.allowed_tenants = -> { ['some-valid-tenant'] }
      config.fail_silently = false
    end

    assert_equal 0, ::Rankmi::Audit::TrackerWorker.jobs.size
    assert_equal 0, Sidekiq::Queues[::Rankmi::Audit::configuration.sidekiq_queue.to_s].size
    ::Rankmi::Audit.track_action(tenant: 'some-valid-tenant', audit_hash: { user_token: '1234', action_type: 'test' })
    assert_equal 1, ::Rankmi::Audit::TrackerWorker.jobs.size
    assert_equal 1, Sidekiq::Queues[::Rankmi::Audit::configuration.sidekiq_queue.to_s].size

    ::Rankmi::Audit.configure do |config|
      config.api_endpoint = 'http://localhost:8090'
      config.api_key = 'SomeKey'
      config.api_secret = 'SomeSecret'
      config.use_sidekiq = true
      config.sidekiq_queue = :audits
      config.allowed_tenants = -> { ['some-valid-tenant'] }
    end

    assert_equal 0, Sidekiq::Queues[::Rankmi::Audit::configuration.sidekiq_queue.to_s].size
    assert_equal 1, Sidekiq::Queues['tracker'].size
    ::Rankmi::Audit.track_action(tenant: 'some-valid-tenant', audit_hash: { user_token: '1234', action_type: 'test' })
    assert_equal 1, Sidekiq::Queues[::Rankmi::Audit::configuration.sidekiq_queue.to_s].size
    assert_equal 1, Sidekiq::Queues['tracker'].size
  end

end
