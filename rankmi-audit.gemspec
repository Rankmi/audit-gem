require_relative 'lib/rankmi/audit/version'

Gem::Specification.new do |spec|
  spec.name          = "rankmi-audit"
  spec.version       = Rankmi::Audit::VERSION
  spec.authors       = ["Rankmi SPA"]

  spec.summary       = %q{Rankmi audit handler}
  spec.description   = %q{Ruby gem for accessing Rankmi Audit API painlessly and easily}

  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency gem 'typhoeus', '~> 1.1'
end
