$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rankmi/audit"

require 'sidekiq/testing'

require "minitest/autorun"
