require_relative 'spec_helper'
require 'json'
require 'os'
require 'yaml'


# It would be nice to test the behavior of requires, loads, and the global config file,
# but those are difficult because they involve modifying directories of the development
# machine that they should not modify. I'm thinking about making the rules configurable,
# but that makes the executable more complex, probably without necessity.


RSpec.describe 'Rexe integration tests' do

  let(:test_data)        {    [ { 'color' => 'blue' }, 200 ] }
  let(:test_data_string) { %Q{[ { 'color' => 'blue' }, 200 ]} }
  let(:load_filespec)    { File.join(File.dirname(__FILE__), 'dummy.rb') }
  let(:readme_filespec)  { File.join(File.dirname(__FILE__), '..', 'README.md') }
  let(:readme_text)      { File.read(readme_filespec) }
  let(:readme_lines)     { File.readlines(readme_filespec) }

  context '-v --version option' do
    specify 'version returned with --version is a valid version string' do
      expect(RUN.("#{REXE_FILE} --version")).to match(/\d+\.\d+\.\d+/)
    end

    specify 'version returned with -v is a valid version string' do
      expect(RUN.("#{REXE_FILE} -v")).to match(/\d+\.\d+\.\d+/)
    end

    specify 'version in README help output matches current version' do

      software_version = RUN.("#{REXE_FILE} --version").chomp
      version_line_regex = %r{rexe -- Ruby Command Line Executor/Filter -- v}

      lines_to_inspect = readme_lines.grep(version_line_regex)
      expect(lines_to_inspect.size).to eq(1)

      readme_version_line = lines_to_inspect.first
      readme_version = readme_version_line.split(' -- ')[2][1..-1]  # remove 'v'

      unless software_version == readme_version
        fail "Version in software was #{software_version.inspect} but " +
                 "version in README help was #{readme_version.inspect}."
      end
    end
  end


  context '-h help text' do
    specify 'includes version' do
      expect(RUN.("#{REXE_FILE} 2>/dev/null -h")).to include(`#{REXE_FILE} --version`.chomp)
    end

    specify 'includes Github URL' do
      expect(RUN.("#{REXE_FILE} -h")).to include('https://github.com/keithrbennett/rexe')
    end
  end


  context '-m input modes' do # (not formats)

    context '-mb big string mode' do
      specify 'all input is considered a single string object' do
        expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -c -mb -op reverse})).to eq("\ndc\nba\n")
      end

      specify 'record count does not exceed 0' do
        expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -mb -op '$RC.i'})).to eq("0\n")
      end
    end


    context '-ml line mode' do
      specify 'each line is processed separately' do
        expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -c -ml -op reverse})).to eq("ba\ndc\n")
      end

      specify 'object count works in numbers > 1' do
        expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -ml -op '$RC.i'})).to eq("0\n1\n2\n")
      end
    end


    context '-me enumerator mode' do
      specify 'self is an Enumerator' do
        expect(RUN.(%Q{echo "ab\ncd" | #{REXE_FILE} -c -me -op self.class.to_s}).chomp).to eq('Enumerator')
      end

      specify 'record count does not exceed 0' do
        expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -me -op '$RC.i'})).to eq("0\n")
      end
    end


    context '-mn no input mode' do
      specify 'in no input mode (-mn), code is executed without input' do
        expect(RUN.(%Q{#{REXE_FILE} -c -mn -op '64.to_s(8)'})).to start_with('100')
      end

      specify '-mn option outputs last evaluated value' do
        expect(RUN.(%Q{#{REXE_FILE} -c -mn -op 42}).chomp).to eq('42')
      end

      specify 'record count does not exceed 0' do
        expect(RUN.(%Q{echo "a\nb\nc" | #{REXE_FILE} -c -mn -op '$RC.i'})).to eq("0\n")
      end
    end
  end


  context '-o output formats' do

    specify '-on no output format results in no output' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn -on 42}).chomp).to eq('')
    end

    specify 'output format defaults to -on (no output)' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn 42}).chomp).to eq('')
    end

    specify '-oj JSON output formatting is correct' do
      command = %Q{#{REXE_FILE} -c -mn -oj "[ { 10 => 100 }, 200 ]" }
      expect(RUN.(command).chomp).to eq(%q{[{"10":100},200]})
    end

    specify '-oJ Pretty JSON output formatting is correct' do
      actual_lines_stripped = RUN.(%Q{#{REXE_FILE} -c -mn -oJ '[ { 10 => 100 }, 200 ]' }).split("\n").map(&:strip)
      expected_lines_stripped = ['[', '{', '"10": 100', '},','200', ']' ]
      expect(actual_lines_stripped).to eq(expected_lines_stripped)
    end

    specify '-oy YAML output formatting is correct' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn -oy '[ { 10 => 100 }, 200 ]' }).chomp).to eq( \
"---
- 10: 100
- 200")
    end

    specify 'inspect (-oi), and to_s (-os) mode return equal and correct strings' do
      inspect_output = RUN.(%Q{#{REXE_FILE} -c -mn -oi '[ { 10 => 100 }, 200 ]' 2>&1})
      to_s_output    = RUN.(%Q{#{REXE_FILE} -c -mn -os '[ { 10 => 100 }, 200 ]' 2>&1})

      expect(to_s_output).to eq(inspect_output)
      expect(to_s_output).to eq(%Q{[{10=>100}, 200]\n})
    end


    specify '-op (puts) format works correctly' do
      puts_output = RUN.(%Q{#{REXE_FILE} -c -mn -op "[ { 10 => 100 }, 200 ]" 2>&1})
      expect(puts_output).to eq( \
%q{{10=>100}
200
})
    end

    specify '-om marshall mode works' do
      data = RUN.(%Q{#{REXE_FILE} -c -mn -om "[ { 10 => 100 }, 200 ]"})
      reconstructed_array = Marshal.load(data)
      expect(reconstructed_array).to be_a(Array)
      expect(reconstructed_array).to eq([ { 10 => 100 }, 200] )
    end
  end


  context '-g logging' do

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

    specify '-gJ option enables log in Pretty JSON format mode' do
      text = RUN.(%Q{#{REXE_FILE} -c -mn -gJ -on String.new 2>&1})
      expect(text.count("\n") > 3).to eq(true)
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


    specify '-gj option enables log in standard JSON format mode' do
      text = RUN.(%Q{#{REXE_FILE} -c -mn -gj -on String.new 2>&1})
      expect(text.count("\n") == 1).to eq(true)
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


    specify '-ga option enables log in Amazing Print format mode' do
      text = RUN.(%Q{#{REXE_FILE} -c -mn -ga -on String.new 2>&1})
      expect(text).to include(':count =>')
      expect(text).to include(':rexe_version =>')
    end

    specify '-gn option disables log' do
      expect(RUN.(%Q{#{REXE_FILE} -c -gn -mn -on 3 2>&1}).chomp).to eq('')
    end

    specify 'not specifying a -g option disables log' do
      expect(RUN.(%Q{#{REXE_FILE} -c -mn -on 3 2>&1}).chomp).to eq('')
    end

    specify '-gm marshall mode works' do
      data = RUN.(%Q{#{REXE_FILE} -c -mn -on -gm String.new 2>&1})
      expect(data.count("\x00") > 0).to eq(true)
      reconstructed_hash = Marshal.load(data)
      expect(reconstructed_hash).to be_a(Hash)
      expect(reconstructed_hash[:count]).to eq(0)
      expect(reconstructed_hash.keys).to include(:duration_secs)
      expect(reconstructed_hash.keys).to include(:options)
      expect(reconstructed_hash.keys).to include(:rexe_version)
      expect(reconstructed_hash[:source_code]).to eq('String.new')
      expect(reconstructed_hash.keys).to include(:start_time)
    end

    specify 'Puts (-gp), inspect (-gi), and to_s (-gs) mode return similar strings' do
      puts_output    = RUN.(%Q{#{REXE_FILE} -c -mn -on -gp String.new 2>&1})
      inspect_output = RUN.(%Q{#{REXE_FILE} -c -mn -on -gi String.new 2>&1})
      to_s_output    = RUN.(%Q{#{REXE_FILE} -c -mn -on -gs String.new 2>&1})

      outputs = [puts_output, inspect_output, to_s_output]

      outputs.each do |output|
        expect(output).to match(/^{:/)
        expect(output).to match(/}$/)
        expect(output).to include(':count=>0')
        expect(output).to include(':rexe_version=>')
        expect(output.count("\n")).to eq(1)
      end
    end
  end


  context '-r requires' do
    specify 'requiring using -r works' do
      RUN.("#{REXE_FILE} -c -mn -op -r yaml YAML") # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).to eq(0)
    end

    specify 'clearing requires using -r ! works' do
      command = "#{REXE_FILE} 2>/dev/null -c -mn -op -r yaml -r! YAML"
      RUN.(command) # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).not_to eq(0)
    end

    specify 'clearing a single require using -r -gem works' do
      command = "#{REXE_FILE} 2>/dev/null -c -mn -op -r yaml -r -yaml YAML"
      RUN.(command) # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).not_to eq(0)
    end
  end

  context '-l loads' do

    specify 'loading using -l works' do
      RUN.("#{REXE_FILE} -c -mn -op -l #{load_filespec} Dummy") # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).to eq(0)
    end

    specify 'clearing loads using -l ! works' do
      command = "#{REXE_FILE} 2>/dev/null -c -mn -op -l #{load_filespec} -l! Dummy"
      RUN.(command) # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).not_to eq(0)
    end

    specify 'clearing a single load using -r -file works' do
      command = "#{REXE_FILE} 2>/dev/null -c -mn -op -l #{load_filespec} -l -#{load_filespec} Dummy"
      RUN.(command) # just refer to the YAML module and see if it breaks
      expect($?.exitstatus).not_to eq(0)
    end

    let (:fs1) { 'spec/dummy.rb'}
    let (:fs2) { 'spec/../spec/dummy.rb'}

    specify 'two different load filespecs that point to the same absolute location are treated as one' do
      command = "#{REXE_FILE} -c -n -gy -l #{fs1} -l #{fs2} 2>&1"
      yaml = RUN.(command) # just refer to the YAML module and see if it breaks
      config = YAML.load(yaml)
      expect(config[:options][:loads].size).to eq(1)
    end
  end


  context '$RC.i rexe context record count' do
    specify 'the record count is available as $RC.count' do
      expect(RUN.(%Q{echo "a\nb\nc" | rexe -ml -op 'self + $RC.count.to_s'})).to eq("a0\nb1\nc2\n")
    end

    specify 'the record count is available as $RC.i' do
      expect(RUN.(%Q{echo "a\nb\nc" | rexe -ml -op 'self + $RC.i.to_s'})).to eq("a0\nb1\nc2\n")
    end
  end


  context '-f file input' do
    specify '-f: text file is read correctly' do
      text = "1\n2\n3\n"
      file_containing(text) do |filespec|
        expect(RUN.(%Q{rexe -f #{filespec} -mb -op self})).to eq(text)
      end
    end

    specify 'text file options are set correctly (not overrided)' do
      file_containing('', '.txt') do |filespec|
        log_yaml = RUN.(%Q{rexe -f #{filespec} -n -gy 2>&1})
        log = YAML.load(log_yaml)
        expect(log[:options][:input_mode]).to   eq(:none)
        expect(log[:options][:input_format]).to eq(:none)
      end
    end

    specify 'YAML file is parsed as YAML without specifying -mb or -iy' do
      array = [1,4,7]
      text = array.to_yaml
      %w(.yml  .yaml  .yaML).each do |extension|
        file_containing(text, extension) do |filespec|
          expect(RUN.(%Q{rexe -f #{filespec} -op 'self == [1,4,7]' }).chomp).to eq('true')
          log_yaml = RUN.(%Q{rexe -f #{filespec} -n -on -gy nil 2>&1 })
          log = YAML.load(log_yaml)
          expect(log[:options][:input_mode]).to   eq(:one_big_string)
          expect(log[:options][:input_format]).to eq(:yaml)
        end
      end
    end

    specify 'JSON file is parsed as JSON without specifying -mb or -ij' do
      array = [1,4,7]
      text = array.to_json
      %w(.json .JsOn).each do |extension|
        file_containing(text, extension) do |filespec|
          expect(RUN.(%Q{rexe -f #{filespec} -op 'self == [1,4,7]' }).chomp).to eq('true')
          log_yaml = RUN.(%Q{rexe -f #{filespec} -n -on -gy nil 2>&1 })
          log = YAML.load(log_yaml)
          expect(log[:options][:input_mode]).to   eq(:one_big_string)
          expect(log[:options][:input_format]).to eq(:json)
        end
      end
    end
  end

  context '-n no op' do
    specify '-n suppresses evaluation' do
      expect(RUN.(%Q{rexe -op    '"hello"'})).to eq("hello\n")
      expect(RUN.(%Q{rexe -op -n '"hello"'})).to eq('')
    end
  end

  context 'source code' do
    specify 'source code is "self" when there no source code is specified' do
      expect(RUN.(%Q{echo '[1,2]' | rexe -ij -ml -oy})).to eq("---\n- 1\n- 2\n")
    end
  end

  context 'article text metadata' do
    specify ' should not be copied to the readme' do
      expect(readme_text).not_to include("---\ntitle: ")
      expect(readme_text).not_to include("[Caution: This is a long article!")
    end
  end

  context 'important strings are frozen' do
    [
        'Rexe::VERSION',
        'Rexe::PROJECT_URL',
        'Rexe::CommandLineParser.new.send(:help_text)'
    ].each do |important_string|
      it "prevents modifying '#{important_string}' because it is frozen" do
        command = %Q{rexe -op '#{important_string} << "foo"' 2>&1}
        output = `#{command}`
        expect(output).to match(/can't modify frozen String/)
      end
    end
  end
end
