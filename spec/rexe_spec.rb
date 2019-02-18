require_relative 'spec_helper'
require 'os'

# It would be nice to test the behavior of requires, loads, and the global config file,
# but those are difficult because they involve modifying directories of the development
# machine that they should not modify. I'm thinking about making the rules configurable,
# but that makes the executable more complex, probably without necessity.

RSpec.describe 'rexe' do

  specify 'version returned with --version is a valid version string' do
    expect(RUN.("#{REXE_FILE} --version")).to match(/\d+\.\d+\.\d+/)
  end

  specify 'help text includes version' do
    expect(RUN.("#{REXE_FILE} -h")).to include(`#{REXE_FILE} --version`.chomp)
  end

  specify 'help text includes Github URL' do
    expect(RUN.("#{REXE_FILE} -h")).to include('https://github.com/keithrbennett/rexe')
  end

  specify 'in big string mode (-mb) all input is considered a single string object' do
    expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -mb reverse})).to eq("\ndc\nba\n")
  end

  specify 'in each line separate mode (-ms) each line is processed separately' do
    expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -ms reverse})).to eq("ba\ndc\n")
  end

  specify 'in enumerator mode (-me) self is an Enumerator' do
    expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -me self.class.to_s}).chomp).to eq('Enumerator')
  end

  specify 'in no input mode (-mn), code is executed without input' do
    expect(RUN.(%Q{#{REXE_FILE} -mn "puts(64.to_s(8))"}).chomp).to eq('100')
  end

  specify '-v option enables verbose mode' do
    expect(RUN.(%Q{#{REXE_FILE} -mn -v 3 2>&1})).to include('rexe version')
  end

  specify '-v n option disables verbose mode' do
    expect(RUN.(%Q{#{REXE_FILE} -v n -mn 3 2>&1})).not_to include('rexe version')
  end

  specify '-mn option does not output anything not explicitly output' do
    expect(RUN.(%Q{#{REXE_FILE} -mn 42}).chomp).to eq('')
  end

  specify 'requiring using -r works' do
    RUN.("#{REXE_FILE} -mn -r! -r yaml YAML") # just refer to the YAML module and see if it breaks
    expect($?.exitstatus).to eq(0)
  end

  specify 'clearing requires using -r ! works' do
    command = "#{REXE_FILE} -mn -r yaml -r! YAML"

    # Suppress distracting error output, but the redirection requires Posix compatibility:
    command << " 2>/dev/null" if OS.posix?

    RUN.(command) # just refer to the YAML module and see if it breaks
    expect($?.exitstatus).not_to eq(0)
  end
end
