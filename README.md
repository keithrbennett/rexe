# Rexe


## Installation

Installation can be performed by either installing the gem or copying the single executable file to your system and ensuring that it is executable:

```gem install rexe```

or

```
curl https://raw.githubusercontent.com/keithrbennett/rexe/master/exe/rexe > rexe
chmod +x rexe
```

## Usage

```

rexe -- Ruby Command Line Filter -- v0.0.1 -- https://github.com/keithrbennett/rexe

Takes standard input and runs the specified code on it, sending the result to standard output.
Your Ruby code can operate on each line individually (-ms) (the default),
or operate on the enumerator of all lines (-me). If the latter, you will probably need to
call chomp on the lines yourself to remove the trailing newlines.

Options:

-h, --help               Print help and exit
-m, --mode MODE          Mode with which to handle input, (-ms for string (default), -me for enumerator)
-r, --require REQUIRES   Gems and built-in libraries (e.g. shellwords, yaml) to require, comma separated
-v, --[no-]verbose       Verbose mode, writes to stderr

If there is an .rexerc file in your home directory, it will be run as Ruby code before processing the input.

If there is an REXE_OPTIONS environment variable, its content will be prepended to the command line
so that you can specify options implicitly (e.g. `export REXE_OPTIONS="-r awesome_print,yaml"`)

```
## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Examples

```
➜  rexe git:(master) ✗   ls | exe/rexe "map(&:reverse).to_s"
["\nelifmeG", "\ntxt.ESNECIL", "\ndm.EMDAER", "\nelifekaR", "\nnib", "\nexe", "\nbil", "\ncepsmeg.cbr", "\nceps"]

➜  rexe git:(master) ✗   uptime | exe/rexe -l split.first
20:51


➜  rexe git:(master) ✗   ls | exe/rexe -r json "to_a.to_json"
["Gemfile\n","LICENSE.txt\n","README.md\n","Rakefile\n","bin\n","exe\n","lib\n","rexe.gemspec\n","spec\n"]


➜  rexe git:(master) ✗   ls | exe/rexe -r yaml "map(&:chomp).to_a.to_yaml"
---
- Gemfile
- LICENSE.txt
- README.md
- Rakefile
- bin
- exe
- lib
- rexe.gemspec
- spec


➜  rexe git:(master) ✗   export REXE_OPTIONS="-r yaml,awesome_print"

➜  rexe git:(master) ✗   ls | exe/rexe "map(&:chomp).to_a.to_yaml"
---
- Gemfile
- LICENSE.txt
- README.md
- Rakefile
- bin
- exe
- lib
- rexe.gemspec
- spec

➜  rexe git:(master) ✗   ls | exe/rexe "map(&:chomp).to_a.ai"
[
    [0] "Gemfile",
    [1] "LICENSE.txt",
    [2] "README.md",
    [3] "Rakefile",
    [4] "bin",
    [5] "exe",
    [6] "lib",
    [7] "rexe.gemspec",
    [8] "spec"
]

```