require "bundler/setup"

REXE_FILE = File.join(File.dirname(__FILE__), '..', 'exe', 'rexe')

# Use this so that testing rexe with requires not in the bundle will load successfully:
RUN = ->(command) { Bundler.with_clean_env { `#{command}` } }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
