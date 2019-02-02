# Rbc

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rbc`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rbc

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rbc.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Examples

```
➜  rbc git:(master) ✗   ls | exe/rbc "map(&:reverse).to_s"
["\nelifmeG", "\ntxt.ESNECIL", "\ndm.EMDAER", "\nelifekaR", "\nnib", "\nexe", "\nbil", "\ncepsmeg.cbr", "\nceps"]

➜  rbc git:(master) ✗   uptime | exe/rbc -l split.first
20:51


➜  rbc git:(master) ✗   ls | exe/rbc -r json "to_a.to_json"
["Gemfile\n","LICENSE.txt\n","README.md\n","Rakefile\n","bin\n","exe\n","lib\n","rbc.gemspec\n","spec\n"]


➜  rbc git:(master) ✗   ls | exe/rbc -r yaml "map(&:chomp).to_a.to_yaml"
---
- Gemfile
- LICENSE.txt
- README.md
- Rakefile
- bin
- exe
- lib
- rbc.gemspec
- spec


➜  rbc git:(master) ✗   export RBC_OPTIONS="-r yaml,awesome_print"

➜  rbc git:(master) ✗   ls | exe/rbc "map(&:chomp).to_a.to_yaml"
---
- Gemfile
- LICENSE.txt
- README.md
- Rakefile
- bin
- exe
- lib
- rbc.gemspec
- spec

➜  rbc git:(master) ✗   ls | exe/rbc "map(&:chomp).to_a.ai"
[
    [0] "Gemfile",
    [1] "LICENSE.txt",
    [2] "README.md",
    [3] "Rakefile",
    [4] "bin",
    [5] "exe",
    [6] "lib",
    [7] "rbc.gemspec",
    [8] "spec"
]

```