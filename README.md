# Rexe

A configurable Ruby command line filter/executor.



## Installation

Installation can be performed by either installing the gem or copying the single executable file to your system and ensuring that it is executable:

```gem install rexe```

or

```
curl https://raw.githubusercontent.com/keithrbennett/rexe/master/exe/rexe > rexe
chmod +x rexe
```

## Usage

rexe is a _filter_ in that it can consume standard input and emit standard output; but it is also an _executor_, meaning it can be used without either standard input or output.

### Help Text

As a summary, here is the help text printed out by the application:

```
exe -- Ruby Command Line Filter -- v0.3.1 -- https://github.com/keithrbennett/rexe

Optionally takes standard input and runs the specified code on it, sending the result to standard output.

Options:

-h, --help                  Print help and exit
-l, --load RUBY_FILE(S)     Ruby file(s) to load, comma separated
-u, --load-up RUBY_FILE(S)  Ruby file(s) to load, searching up tree, comma separated
-m, --mode MODE             Mode with which to handle input (i.e. what `self` will be in the code):
                           -ms for each line to be handled separately as a string (default)
                           -me for an enumerator of lines (least memory consumption for big data)
                           -mb for 1 big string (all lines combined into single multiline string)
                           -mn to execute the specified Ruby code on no input at all
-r, --require REQUIRES   Gems and built-in libraries (e.g. shellwords, yaml) to require, comma separated
-v, --[no-]verbose       Verbose mode (logs to stderr) Verbose off short options: -v n, -v false

If there is an .rexerc file in your home directory, it will be run as Ruby code
before processing the input.

If there is an REXE_OPTIONS environment variable, its content will be prepended to the command line
so that you can specify options implicitly (e.g. `export REXE_OPTIONS="-r awesome_print,yaml"`)
```

### Input Mode

When it is used as a filter, the input is accessed differently in the source code depending on the mode that was specified (see example section below for examples). The mode letter is appended to `-m` on the command line; `s` (_string_) mode is the default.

* `s` - _string_ mode - the source code is run once on each line of input, and `self` is each line of text
* `e` - _enumerator_ mode - the code is run once on the enumerator of all lines; `self` is the enumerator, so you can call `map`, `to_a`, `select`, etc without explicitly specifying `self`.
* `b` - _big string_ mode - all input is treated as one large (probably) multiline string with the newlines intact; `self` is this large string; this mode is required, for example, for parsing the text into a single object from JSON or YAML formatted data.
* `n` - _no input_ mode - this instructs the program to proceed without looking for input


### Requires

As with the Ruby interpreter itself, `require`s can be specified on the command line with the `-r` option. Multiple requires can be combined with commas between them.


### Loading Ruby Files

Other Ruby files can be loaded by `rexe`, to, for example, define classes and methods to use, set up resources, etc. They are specified with the `-l` option.

If there is a file named `.rexerc` in the home directory, that will always be loaded without explicitly requesting it on the command line.

#### Searching for Load Files in the Current Directory and Above

Using the `-u` option, you can specify that the file you want to load should be searched for at the specified directory _and above_. This can be handy when you have project specific configuration and you may be multiple levels below the project root.

For example, if you run `rexe` from `~/my_project/a/b/c`, and specify `-u load-me.rb`, and `load-me.rb` is located in `~/my_project`, then it will be loaded from there.

If the file is not found, the failure will be silent and the program will proceed. (Preferred behavior could go either way on this, but the current approach enables you to unconditionally specify a `-u` file in your default `REXE_OPTIONS` environment variable value and have it work regardless of the presence or absence of the file.) If verbose mode is enabled, a message about the failure to find the file will be displayed.

### Verbose Mode

Verbose mode outputs information to standard error (stderr). This information can be redirected, for example to a file named `rexe.log`, by adding `2>& rexe.log` to the command line.

Here is an example of some text that might be output in verbose mode:

```
➜  ~   rexe -r yaml -mn -v "%w(foo bar baz).to_yaml"
rexe version 0.3.0 -- 2019-02-08 02:21:27 +0700
Source Code: %w(foo bar baz).to_yaml
Options: {:input_mode=>:no_input, :loads=>[], :requires=>["yaml"], :verbose=>true}
Loading global config file /Users/kbennett/.rexerc
---
- foo
- bar
- baz
rexe time elapsed: 0.03874 seconds.
```

To set verbose mode _off_ on the command line, the option parser accepts the long option `--no-verbose`, of course, but you could use instead `-v false` or `-v n`. If you should need to pass a value to `-v` to turn verbose mode _on_, then you can use `-v y` or `-v true`. 

### The REXE_OPTIONS Environment Variable

Very often you will want to call `rexe` several times with similar options. Instead of having to clutter the command line each time with these options, you can put them in an environment variable named `REXE_OPTIONS`, and they will be prepended automatically. Since they will be processed before the options on the command line, they are of lower precedence and can be overridden.


### The ~/.rexerc Configuation File

The `.rexerc` file in your home directory (if it exists) is loaded unconditionally. Here is a place to put things that you will _always_ want. You can include commonly needed requires, but be careful because the impact on startup time may be more than you want. You can test this using verbose mode, which outputs the execution time after completing.


### Directory-Specific Configuration Files

Although there is no built-in feature for directory-specific configuration files, this can be easily accomplished by inserting something like this in your global configuration file (~/.rexerc):

```
dir_specific_config_file = './rexe.rc'
load dir_specific_config_file' if File.exist?(dir_specific_config_file)
```
 
You should probably put this at the very end of this global configuration file so that the directory specific file will always be able to override global settings.

Note that the directory specific filename used differs from the global config filename. This is a) so that there is no recursive loading of the file when in the home directory, and b) because it is more convenient for these files that they not be hidden.


## Troubleshooting

One common problem relates to the shell's special handling of characters. Remember that the shell will process special characters, thereby changing your text before passing it on to the Ruby code. It is good to get in the habit of putting your source code in double quotes; and if the source code itself uses quotes, use `q{}` or `Q{}` instead. For example:

```
➜   rexe -mn "puts %Q{The time is now #{Time.now}}"
The time is now 2019-02-04 18:49:31 +0700
```

If you are troubleshooting the setup (i.e. the command line options, loaded files, and `REXE_OPTIONS` environment variable) using the verbose option, you may have the problem of the logging scrolling off the screen due to the length of your output. In this case you could easily fake or disable the output adding `; nil`, `; 'foo'`', etc. to the end of your expression. This way you don't have to mess with your code's logic.

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

# Now that command that previously failed will succeed:
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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
