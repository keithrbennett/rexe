
Gem::Specification.new do |spec|
  spec.name          = "rexe"

  spec.version       = -> do
    # This is a bit of a kludge. If there is a commented out VERSION line preceding the active line,
    # this will read the commented line.
    # TODO: Ignore comment lines.
    rexe_file = File.join(File.dirname(__FILE__), 'exe', 'rexe')
    version_line = File.readlines(rexe_file).grep(/\s*VERSION\s*=\s*'/).first.chomp
    version_line.match(/'(.+)'/)[0].gsub("'", '')
  end.()

  spec.authors       = ["Keith Bennett"]
  spec.email         = ["keithrbennett@gmail.com"]

  spec.summary       = %q{Ruby Command Line Executor}
  spec.description   = %q{Ruby Command Line Executor}
  spec.homepage      = "https://github.com/keithrbennett/rexe"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org/"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/keithrbennett/rexe"
    spec.metadata["changelog_uri"] = "https://github.com/keithrbennett/rexe/blob/master/README.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "awesome_print"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "os"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.12"

  # Remove this message (added November 2023) later (maybe July 2024).
  spec.post_install_message = <<~MESSAGE
    Starting with v1.6.1, awesome_print is now used instead of amazing_print 
    for fancy human readable output. Rexe will still function without it, 
    but if it is present, it will be used.
  MESSAGE
end
