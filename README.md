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

rexe -- Ruby Command Line Filter -- v0.0.2 -- https://github.com/keithrbennett/rexe

Takes standard input and runs the specified code on it, sending the result to standard output.

Options:

-h, --help               Print help and exit
-l, --load A_RUBY_FILE              Load this Ruby source code file
-m, --mode MODE          Mode with which to handle input (i.e. what `self` will be in the code):
                           -ms for each line to be handled separately as a string (default)
                           -me for an enumerator of lines (least memory consumption for big data)
                           -mb for 1 big string (all lines combined into single multiline string)
                           -mn to execute the specified Ruby code on no input at all
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
# Call reverse on listed file.
# No need to specify the mode, since it defaults to "s" ("-ms"),
# which treats every line separately.
➜  rexe git:(master) ✗   ls | head -2 | exe/rexe "self + ' --> ' + reverse"
CHANGELOG.md --> dm.GOLEGNAHC
Gemfile --> elifmeG

----

# Use input data to create a human friendly message:
➜  ~   uptime | rexe "%Q{System has been up: #{split.first}.}"
System has been up: 17:10.

----

# Create a JSON array of a file listing.
# Use the "-me" flag so that all input is treated as a single enumerator of lines.
➜  /etc   ls | head -3 | rexe -me -r json "map(&:strip).to_a.to_json"
["AFP.conf","afpovertcp.cfg","afpovertcp.cfg~orig"]

----

# Create a "pretty" JSON array of a file listing:
➜  /etc   ls | head -3 | rexe -me -r json "JSON.pretty_generate(map(&:strip).to_a)"
[
  "AFP.conf",
  "afpovertcp.cfg",
  "afpovertcp.cfg~orig"
]

----

# Create a YAML array of a file listing:
➜  /etc   ls | head -3 | rexe -me -r yaml "map(&:strip).to_a.to_yaml"
---
- AFP.conf
- afpovertcp.cfg
- afpovertcp.cfg~orig

----

# Use AwesomePrint to print a file listing.
# (Rather than calling the `ap` method on the object to print, 
# call the `ai` method _on_ the object to print:
➜  /etc   ls | head -3 | rexe -me -r awesome_print "map(&:chomp).ai"
[
    [0] "AFP.conf",
    [1] "afpovertcp.cfg",
    [2] "afpovertcp.cfg~orig"
]

----

# Don't use input at all, so use "-mn" to tell rexe not to expect input.
➜  /etc   rexe -mn "%Q{The time is now #{Time.now}}"
The time is now 2019-02-04 17:20:03 +0700

----

# Use REXE_OPTIONS environment variable to eliminate the need to specify
# options on each invocation:

# First it will fail since these symbols have not been loaded via require:
➜  /etc   rexe -mn "[JSON, YAML, AwesomePrint]"
Traceback (most recent call last):
...
(eval):1:in `block in call': uninitialized constant Rexe::JSON (NameError)

# Now we specify the requires in the REXE_OPTIONS environment variable.
# Contents of this variable will be prepended to the arguments
# specified on the command line.
➜  /etc   export REXE_OPTIONS="-r json,yaml,awesome_print"
➜  /etc   rexe -mn "[JSON, YAML, AwesomePrint].to_s"
[JSON, Psych, AwesomePrint]

----

Access public JSON data and print it with awesome_print:

➜  /etc   curl https://data.lacity.org/api/views/nxs9-385f/rows.json\?accessType\=DOWNLOAD \
 | rexe -mb -r awesome_print,json "JSON.parse(self).ai"
 {
     "meta" => {
         "view" => {
                                   "id" => "nxs9-385f",
                                 "name" => "2010 Census Populations by Zip Code",
...

----

# Print the environment variables, sorted, with Awesome Print:
➜  /etc   env | rexe -me -r awesome_print sort.to_a.ai
[
...
    [ 4] "COLORFGBG=15;0\n",
    [ 5] "COLORTERM=truecolor\n",
...    
```