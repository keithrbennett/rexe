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


# From the trick_bag gem:
require 'tempfile'

# For the easy creation and deletion of a temp file populated with text,
# wrapped around the code block you provide.
#
# @param text the text to write to the temporary file
# @yield filespec of the temporary file
def file_containing(text, extension = nil)
  raise "This method must be called with a code block." unless block_given?

  filespec = nil
  begin
    Tempfile.open(['rexe-spec-', extension]) do |file|
      file << text
      filespec = file.path
    end
    yield(filespec)
  ensure
    File.delete(filespec) if filespec && File.exist?(filespec)
  end
end
