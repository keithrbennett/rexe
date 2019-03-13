require_relative 'spec_helper'
require 'json'
require 'os'
require 'yaml'


# It would be nice to test the behavior of requires, loads, and the global config file,
# but those are difficult because they involve modifying directories of the development
# machine that they should not modify. I'm thinking about making the rules configurable,
# but that makes the executable more complex, probably without necessity.


RSpec.describe 'rexe' do


  context '--version option' do
    specify 'version returned with --version is a valid version string' do
      expect(RUN.("#{REXE_FILE} --version")).to match(/\d+\.\d+\.\d+/)
    end
  end


  context 'help text' do
    specify 'help text includes version' do
      expect(RUN.("#{REXE_FILE} -h")).to include(`#{REXE_FILE} --version`.chomp)
    end

    specify 'help text includes Github URL' do
      expect(RUN.("#{REXE_FILE} -h")).to include('https://github.com/keithrbennett/rexe')
    end
  end


  context '-mb big string mode' do
    specify 'in big string mode (-mb) all input is considered a single string object' do
      expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -c -mb reverse})).to eq("\ndc\nba\n")
    end

    specify 'record count does not exceed 0' do
      expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -mb '$RC.i'})).to eq("0\n")
    end
  end


  context '-ml line mode' do
    specify 'each line is processed separately' do
      expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -c -ml reverse})).to eq("ba\ndc\n")
    end

    specify 'object count works in numbers > 1' do
      expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -ml '$RC.i'})).to eq("0\n1\n2\n")
    end
  end


  context '-me enumerator mode' do
    specify 'self is an Enumerator' do
      expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -c -me self.class.to_s}).chomp).to eq('Enumerator')
    end

    specify 'record count does not exceed 0' do
      expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -me '$RC.i'})).to eq("0\n")
    end
  end


  context '-mn no input mode' do
    specify 'in no input mode (-mn), code is executed without input' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn "puts(64.to_s(8))"})).to start_with('100')
    end

    specify '-mn option outputs last evaluated value' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn 42}).chomp).to eq('42')
    end

    specify 'record count does not exceed 0' do
      expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -mn '$RC.i'})).to eq("0\n")
    end
  end



    context 'logging' do

     specify '-gy option enables log in YAML format mode' do
       text = RUN.(%Q{#{REXE_FILE} -c -mn -gy -on String.new 2>&1})
       reconstructed_hash = YAML.load(text)
       expect(reconstructed_hash).to be_a(Hash)
       expect(reconstructed_hash[:count]).to eq(0)
       expect(reconstructed_hash.keys).to include(:duration_secs)
       expect(reconstructed_hash.keys).to include(:options)
       expect(reconstructed_hash.keys).to include(:rexe_version)
       expect(reconstructed_hash[:source_code]).to eq('String.new')
       expect(reconstructed_hash.keys).to include(:start_time)
    end

     specify '-gj option enables log in JSON format mode' do
       text = RUN.(%Q{#{REXE_FILE} -c -mn -gJ -on String.new 2>&1})
       reconstructed_hash = JSON.parse(text)

       expect(reconstructed_hash).to be_a(Hash)
       expect(reconstructed_hash.keys).to include('duration_secs')
       expect(reconstructed_hash.keys).to include('options')
       expect(reconstructed_hash.keys).to include('rexe_version')
       expect(reconstructed_hash.keys).to include('start_time')

       # Note below that the keys below are parsed as a String, not its original type, Symbol:
       expect(reconstructed_hash['count']).to eq(0)
       expect(reconstructed_hash['source_code']).to eq('String.new')
     end

     specify '-gn option disables log' do
      expect(RUN.(%Q{#{REXE_FILE} -c -gn -mn 3 2>&1})).not_to include('rexe version')
    end

    specify 'not specifying a -g option disables log' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn 3 2>&1})).not_to include('rexe version')
    end
  end


  context '-on no output mode' do
    specify '-on output format results in no output' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn -on 42}).chomp).to eq('')
    end
  end


  context 'requires' do
    specify 'requiring using -r works' do
      RUN.("#{REXE_FILE} -c -mn -r! -r yaml YAML") # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).to eq(0)
    end

    specify 'clearing requires using -r ! works' do
      command = "#{REXE_FILE} -c -mn -r yaml -r! YAML"

      # Suppress distracting error output, but the redirection requires Posix compatibility:
      command << " 2>/dev/null" if OS.posix?

      RUN.(command) # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).not_to eq(0)
    end
  end


  context 'rexe context record count' do
    specify 'the record count is available as $RC.count' do
      expect(RUN.(%Q{echo "a\nb\nc" | rexe -ml 'self + $RC.count.to_s'})).to eq("a0\nb1\nc2\n")
    end

    specify 'the record count is available as $RC.i' do
      expect(RUN.(%Q{echo "a\nb\nc" | rexe -ml 'self + $RC.i.to_s'})).to eq("a0\nb1\nc2\n")
    end
  end

end
