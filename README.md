# Rexe

__Rexe__ is a Ruby script and gem that multiplies Ruby's usefulness and conciseness on the command line by:

* automating parsing and formatting using JSON, YAML, Ruby marshalling, Awesome Print, and others
* simplifying the use of Ruby as a shell filter, optionally predigesting input as lines, an enumerator, or one big string
* extracting the plumbing from the command line; requires and other options can be set in an environment variable
* enabling the loading of Ruby helper files to keep your code DRY and your command line code high level
* reading and evaluating a ~/.rexerc file on startup for your shared custom code and common requires

----

Shell scripting is great for simple tasks but for anything nontrivial it can easily get cryptic and awkward (pun intended!).

This problem can often be solved by writing a Ruby script instead. Ruby provides fine grained control in a language that is all about clarity, conciseness, and expressiveness.

Unfortunately, when there are multiple OS commands to be called, then Ruby can be awkward too.

Sometimes a good solution is to combine Ruby and shell scripting on the same command line. Rexe multiplies your power to do so.


### Using the Ruby Interpreter on the Command Line

Let's start by seeing what the Ruby interpreter already provides. Here we use `ruby` on the command line, using an intermediate environment variable to simplify the logic and save the data for use by future commands. An excerpt of the output follows the code:

```bash
➜  ~   export EUR_RATES_JSON=`curl https://api.exchangeratesapi.io/latest`
➜  ~   echo $EUR_RATES_JSON | ruby -r json -r yaml -e 'puts JSON.parse(STDIN.read).to_yaml'
```
```yaml
---
rates:
  MXN: 21.96
  AUD: 1.5964
  HKD: 8.8092
  ...
base: EUR
date: '2019-03-08'
```

Unfortunately, the configuration setup (the `require`s) along with the reading, parsing, and formatting make the command long and tedious, discouraging this approach.

### Rexe

Rexe [see footnote ^1 regarding its origin] can simplify such commands. Among other things, rexe provides switch-activated input parsing and output formatting so that converting from one format to another is trivial. The previous `ruby` command can be expressed in `rexe` as:

```bash
➜  ~   echo $EUR_RATES_JSON | rexe -mb -ij -oy self
```

Or, even more concisely (`self` is the default Ruby source code for rexe commands):

```bash
➜  ~   echo $EUR_RATES_JSON | rexe -mb -ij -oy
```

The command options may seem cryptic, but they're logical so it shouldn't take long to learn them:

* `-mb` - __mode__ to consume all standard input as a single __big__ string
* `-ij` - parse that __input__ with __JSON__; `self` will be the parsed object
* `-oy` - __output__ the final value as __YAML__
 
If input comes from a JSON or YAML file, rexe determines the input format from the file's extension, and it's even simpler:

```bash
➜  ~   rexe -f eur_rates.json -oy
```

Rexe is at https://github.com/keithrbennett/rexe and can be installed with `gem install rexe`. Rexe provides several ways to simplify Ruby on the command line, tipping the scale so that it is practical to do it more often.

----

Here is rexe's help text as of the time of this writing:

```
rexe -- Ruby Command Line Executor/Filter -- v1.3.1 -- https://github.com/keithrbennett/rexe

Executes Ruby code on the command line, 
optionally automating management of standard input and standard output,
and optionally parsing input and formatting output with YAML, JSON, etc.

rexe [options] [Ruby source code]

Options:

-c  --clear_options        Clear all previous command line options specified up to now
-f  --input_file           Use this file instead of stdin for preprocessed input; 
                           if filespec has a YAML and JSON file extension,
                           sets input format accordingly and sets input mode to -mb
-g  --log_format FORMAT    Log format, logs to stderr, defaults to -gn (none)
                           (see -o for format options)
-h, --help                 Print help and exit
-i, --input_format FORMAT  Input format, defaults to -in (None)
                             -ij  JSON
                             -im  Marshal
                             -in  None (default)
                             -iy  YAML
-l, --load RUBY_FILE(S)    Ruby file(s) to load, comma separated;
                             ! to clear all, or precede a name with '-' to remove
-m, --input_mode MODE      Input preprocessing mode (determines what `self` will be)
                           defaults to -mn (none)
                             -ml  line; each line is ingested as a separate string
                             -me  enumerator (each_line on STDIN or File)
                             -mb  big string; all lines combined into one string
                             -mn  none (default); no input preprocessing; 
                                  self is an Object.new 
-n, --[no-]noop            Do not execute the code (useful with -g);
                           For true: yes, true, y, +; for false: no, false, n
-o, --output_format FORMAT Output format, defaults to -on (no output):
                             -oa  Awesome Print
                             -oi  Inspect
                             -oj  JSON
                             -oJ  Pretty JSON
                             -om  Marshal
                             -on  No Output (default)
                             -op  Puts
                             -oP  Pretty Print
                             -os  to_s
                             -oy  YAML
                             If 2 letters are provided, 1st is for tty devices, 2nd for block
--project-url              Outputs project URL on Github, then exits
-r, --require REQUIRE(S)   Gems and built-in libraries to require, comma separated;
                             ! to clear all, or precede a name with '-' to remove
-v, --version              Prints version and exits

---------------------------------------------------------------------------------------
                                                                                            
In many cases you will need to enclose your source code in single or double quotes.

If source code is not specified, it will default to 'self', 
which is most likely useful only in a filter mode (-ml, -me, -mb).

If there is a .rexerc file in your home directory, it will be run as Ruby code 
before processing the input.

If there is a REXE_OPTIONS environment variable, its content will be prepended
to the command line so that you can specify options implicitly 
(e.g. `export REXE_OPTIONS="-r awesome_print,yaml"`)
```

### Simplifying the Rexe Invocation

There are two main ways we can make the rexe command line even more concise:

* by extracting configuration into the `REXE_OPTIONS` environment variable
* by extracting low level and/or shared code into helper files that are loaded using `-l`,
  or implicitly with `~/.rexerc`


### The REXE_OPTIONS Environment Variable

The `REXE_OPTIONS` environment variable can contain command line options that would otherwise be specified on the rexe command line:

Instead of this:

```bash
➜  ~   rexe -r wifi-wand -oa WifiWand::MacOsModel.new.wifi_info
```

you can do this:

```bash
➜  ~   export REXE_OPTIONS="-r wifi-wand -oa"
➜  ~   rexe WifiWand::MacOsModel.new.wifi_info
➜  ~   # [more rexe commands with the same options]
```

Putting configuration options in `REXE_OPTIONS` effectively creates custom defaults, and is useful when you use the same options in most or all of your commands. Any options specified on the rexe command line will override the environment variable options.

Like any environment variable, `REXE_OPTIONS` could also be set in your startup script, input on a command line using `export`, or in another script loaded with `source` or `.`.

### Loading Files

The environment variable approach works well for command line _options_, but what if we want to specify Ruby _code_ (e.g. methods) that can be used by your rexe code?

For this, rexe lets you _load_ Ruby files, using the `-l` option, or implicitly (without your specifying it) in the case of the `~/.rexerc` file. Here is an example of something you might include in such a file:

```ruby
# Open YouTube to Wagner's "Ride of the Valkyries"
def valkyries
  `open "http://www.youtube.com/watch?v=P73Z6291Pt8&t=0m28s"`
end
```

To digress a bit, why would you want this? You might want to be able to go to another room until a long job completes, and be notified when it is done.  The `valkyries` method will launch a browser window pointed to Richard Wagner's "Ride of the Valkyries" starting at a lively point in the music [see footnote ^2 regarding autoplay]. (The `open` command is Mac specific and could be replaced with `start` on Windows, a browser command name, etc.) [see footnote ^3 regarding OS portability].
 
 If you like this kind of audio notification, you could download public domain audio files and use a command like player like `afplay` on Mac OS, or `mpg123` or `ogg123` on Linux. This approach is lighter weight, requires no network access, and will not leave an open browser window for you to close.

Here is an example of how you might use the `valkyries` method, assuming the above configuration is loaded from your `~/.rexerc` file or an explicitly loaded file:

```bash
➜  ~   tar czf /tmp/my-whole-user-space.tar.gz ~ ; rexe valkyries
```

(Note that `;` is used rather than `&&` because we want to hear the music whether or not the command succeeds.)

You might be thinking that creating an alias or a minimal shell script (instead of a Ruby script) for this `open` would be a simpler and more natural approach, and I would agree with you. However, over time the number of these could become unmanageable, whereas using Ruby you could build a pretty extensive and well organized library of functionality. Moreover, that functionality could be made available to _all_ your Ruby code (for example, by putting it in a gem), and not just command line one liners.

For example, you could have something like this in a gem or loaded file:

```ruby
def play(piece_code)
  pieces = {
    hallelujah: "https://www.youtube.com/watch?v=IUZEtVbJT5c&t=0m20s",
    valkyries:  "http://www.youtube.com/watch?v=P73Z6291Pt8&t=0m28s",
    wm_tell:    "https://www.youtube.com/watch?v=j3T8-aeOrbg&t=0m1s",
    # ... and many, many more
  }
  `open #{Shellwords.escape(pieces.fetch(piece_code))}`
end
```

...which you could then call like this:

```bash
➜  ~   tar czf /tmp/my-whole-user-space.tar.gz ~ ; rexe 'play(:hallelujah)'
```

(You need to quote the `play` call because otherwise the shell will process and remove the parentheses. Alternatively you could escape the parentheses with backslashes.)

One of the examples at the end of this articles shows how you could have different music play for success and failure.


### Logging

A log entry is optionally output to standard error after completion of the code. This entry is a hash representation (to be precise, `to_h`) of the `$RC` OpenStruct described in the $RC section below. It contains the version, date/time of execution, source code to be evaluated, options (after parsing both the `REXE_OPTIONS` environment variable and the command line), and the execution time of your Ruby code:
 
```bash
➜  ~   echo $EUR_RATES_JSON | rexe -gy -ij -mb -oa -n self
```
```yaml
---
:count: 0
:rexe_version: 1.3.1
:start_time: '2019-09-11T13:28:46+07:00'
:source_code: self
:options:
  :input_filespec:
  :input_format: :json
  :input_mode: :one_big_string
  :loads: []
  :output_format: :awesome_print
  :output_format_tty: :awesome_print
  :output_format_block: :awesome_print
  :requires:
  - awesome_print
  - json
  - yaml
  :log_format: :yaml
  :noop: true
:duration_secs: 0.095705
```

We specified `-gy` for YAML format; there are other formats as well (see the help output or this document) and the default is `-gn`, which means don't output the log entry at all.

The requires you see were not explicitly specified but were automatically added because Rexe will add any requires needed for automatic parsing and formatting, and we specified those formats in the command line options `-gy -ij -oa`.
 
This extra output is sent to standard error (_stderr_) instead of standard output (_stdout_) so that it will not pollute the "real" data when stdout is piped to another command.

If you would like to append this informational output to a file(e.g. `rexe.log`), you could do something like this:

```bash
➜  ~   rexe ... -gy 2>>rexe.log
```


### Input Modes

Rexe tries to make it simple and convenient for you to handle standard input, and in different ways. Here is the help text relating to input modes:

```
-m, --input_mode MODE      Input preprocessing mode (determines what `self` will be)
                           defaults to -mn (none)
                             -ml  line; each line is ingested as a separate string
                             -me  enumerator (each_line on STDIN or File)
                             -mb  big string; all lines combined into one string
                             -mn  none (default); no input preprocessing;
                                  self is an Object.new
```

The first three are _filter_ modes; they make standard input available to your code as `self`.

The last (and default) is the _executor_ mode. It merely assists you in executing the code you provide without any special implicit handling of standard input. Here is more detail on these modes:


#### -ml "Line" Filter Mode

In this mode, your code would be called once per line of input, and in each call, `self` would evaluate to each line of text:

```bash
➜  ~   echo "hello\ngoodbye" | rexe -ml puts reverse
olleh
eybdoog
```

`reverse` is implicitly called on each line of standard input.  `self` is the input line in each call (we could also have used `self.reverse` but the `self.` would have been redundant).
  
Be aware that, in this mode, if you are using an automatic output mode (anything other than the default `-on` no output mode), although you can control the _content_ of output records, there is no way to selectively _exclude_ records from being output. Even if the result of the code is nil or the empty string, a newline will be output. To prevent this, you can do one of the following:
 
 * use `-me` Enumerator mode instead and call `select`, `filter`, `reject`, etc.
 * use the (default) `-on` _no output_ mode and call `puts` explicitly for the output you _do_ want


#### -me "Enumerator" Filter Mode

In this mode, your code is called only once, and `self` is an enumerator dispensing all lines of standard input. To be more precise, it is the enumerator returned by the `each_line` method, on `$stdin` or the input file, whichever is applicable.

Dealing with input as an enumerator enables you to use the wealth of `Enumerable` methods such as `select`, `to_a`, `map`, etc.

Here is an example of using `-me` to add line numbers to the first 3 files in the directory listing:

```bash
➜  ~   ls / | rexe -me "first(3).each_with_index { |ln,i| puts '%5d  %s' % [i, ln] }"

    0  AndroidStudioProjects
    1  Applications
    2  Desktop
```

Since `self` is an enumerable, we can call `first` on it. We've used the default output mode `-on` (_no output_ mode), which says don't do any automatic output, just the output explicitly specified by `puts` in the source code.


#### -mb "Big String" Filter Mode

In this mode, all standard input is combined into a single (possibly large and possibly multiline) string.

A good example of when you would use this is when you need to parse a multiline JSON or YAML representation of an object; you need to pass all the standard input to the parse method. This is the mode that was used in the first rexe example in this article.


#### -mn "No Input" Executor Mode -- The Default

In this mode, no special handling of standard input is done at all; if you want standard input you need to code it yourself (e.g. with `STDIN.read`).

`self` evaluates to a new instance of `Object`, which would be used if you defined methods, constants, instance variables, etc., in your code.


#### Filter Input Mode Memory Considerations

If you are using one of the filter modes, and may have more input than would fit in memory, you can do one of the following:

* use `-ml` (line) mode so you are fed only 1 line at a time
* use an Enumerator, either by a) specifying the `-me` (enumerator) mode option,
 or b) using `-mn` (no input) mode in conjunction with something like `STDIN.each_line`. Then: 
  * Make sure not to call any methods (e.g. `map`, `select`)
 that will produce an array of all the input because that will pull all the records into memory, or:
  * use [lazy enumerators](https://www.honeybadger.io/blog/using-lazy-enumerators-to-work-with-large-files-in-ruby/)
 

### Input Formats

Rexe can parse your input in any of several formats if you like. You would request this in the _input format_ (`-i`) option. Legal values are:

* `-ij` - JSON
* `-im` - Marshal
* `-in` - [None] (default)
* `-iy` - YAML

Except for `-in`, which passes the text to your code untouched, your input will be parsed in the specified format, and the resulting object passed into your code as `self`.

The input format option is ignored if the input _mode_ is `-mn` ("no input" executor mode, the default), since there is no preprocessing of standard input in that mode.

### Output Formats

Several output formats are provided for your convenience:

* `-oa` - Awesome Print - calls `.ai` on the object to get the string that `ap` would print
* `-oi` - Inspect - calls `inspect` on the object
* `-oj` - JSON - calls `to_json` on the object
* `-oJ` - Pretty JSON calls `JSON.pretty_generate` with the object
* `-on` - (default) No Output - output is suppressed
* `-op` - Puts - produces what `puts` would output
* `-os` - To String - calls `to_s` on the object
* `-oy` - YAML - calls `to_yaml` on the object

All formats will implicitly `require` anything needed to accomplish their task (e.g. `require 'yaml'`).

The default is `-on` to produce no output at all (unless explicitly coded to do so). If you prefer a different default such as `-op` for _puts_ mode, you can specify that in your `REXE_OPTIONS` environment variable.

If two letters are provided, the first will be used for tty devices (e.g. the terminal when not redirected or piped), and the second for block devices (e.g. when redirected or piped to another process).

You may wonder why these formats are provided, given that their functionality could be included in the custom code instead. Here's why:

* The savings in command line length goes a long way to making these commands more readable and feasible.
* It's much simpler to switch formats, as there is no need to change the code itself.
* This approach enables parameterization of the output format.


### Reading Input from a File

Rexe also simplifies getting input from a file rather than standard input. The `-f` option takes a filespec and does with its content exactly what it would have done with standard input. This shortens:

```bash
➜  ~   cat filename.ext | rexe ...
```
...to...

```bash
➜  ~   rexe -f filename.ext ...
```

This becomes even more useful if you are using files whose extensions are `.yml`, `.yaml`, or `.json` (case insensitively). In this case the input format and mode will be set automatically for you to:

* `-iy` (YAML) or `-ij` (JSON) depending on the file extension
* `-mb` (one big string mode), which assumes that the most common use case will be to parse the entire file at once

So the example we gave above:

```bash
➜  ~   export EUR_RATES_JSON=`curl https://api.exchangeratesapi.io/latest`
➜  ~   echo $EUR_RATES_JSON | rexe -mb -ij -oy self
```
...could be changed to:

```bash
➜  ~   curl https://api.exchangeratesapi.io/latest > eur_rates.json
➜  ~   rexe -f eur_rates.json -oy self
``` 

Another possible win for using `-f` is that since it is a command line option, it could be specified in `REXE_OPTIONS`. This could be useful if you are doing many operations on the same file.

If you need to override the input mode and format automatically configured for file input, you can simply specify the desired options on the command line _after_ the `-f`:

```bash
➜  ~   rexe -f eur_rates.json -mb -in 'puts self.class, self[0..20]'
String
{"base":"EUR","rates"
```


### 'self' as Default Source Code

To make rexe even more concise, you do not need to specify any source code when you want that source code to be `self`. This would be the case for simple format conversions, as in JSON to YAML conversion mentioned above:

```bash
➜ ~  rexe -f eur_rates.json -oy
# or
➜ ~  echo $EUR_RATES_JSON | rexe -mb -ij -oy
```
```yaml
---
rates:
  JPY: 126.63
  BRL: 4.3012
  NOK: 9.6915
  ...
```

This feature is probably only useful in the filter modes, since in the executor mode (`-mn`) self is a new instance of `Object` and hardly ever useful as an output value.

### The $RC Global OpenStruct

For your convenience, the information displayed in verbose mode is available to your code at runtime by accessing the `$RC` global variable, which contains an OpenStruct. Let's print out its contents using YAML:
 
```bash
➜  ~   rexe -oy '$RC'
```
```yaml
--- !ruby/object:OpenStruct
table:
  :count: 0
  :rexe_version: 1.3.1
  :start_time: '2019-09-11T13:25:53+07:00'
  :source_code: "$RC"
  :options:
    :input_filespec: 
    :input_format: :none
    :input_mode: :none
    :loads: []
    :output_format: :yaml
    :output_format_tty: :yaml
    :output_format_block: :yaml
    :requires:
    - yaml
    :log_format: :none
    :noop: false
modifiable: true
``` 
 
Probably most useful in that object at runtime is the record count, accessible with both `$RC.count` and `$RC.i`. This is only really useful in line mode, because in the others it will always be 0 or 1. Here is an example of how you might use it as a kind of progress indicator:

```bash
➜  ~   find / | rexe -ml -on \
'if $RC.i % 1000 == 0; puts %Q{File entry ##{$RC.i} is #{self}}; end'
```
```
...
File entry #106000 is /usr/local/Cellar/go/1.11.5/libexec/src/cmd/vendor/github.com/google/pprof/internal/driver/driver_test.go
File entry #107000 is /usr/local/Cellar/go/1.11.5/libexec/src/go/types/testdata/cycles1.src
File entry #108000 is /usr/local/Cellar/go/1.11.5/libexec/src/runtime/os_linux_novdso.go
...
```

Note that a single quote was used for the Ruby code here; if a double quote were used, the `$RC` would have been interpreted and removed by the shell.
  

### Implementing Domain Specific Languages (DSL's)

Defining methods in your loaded files enables you to effectively define a [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) for your command line use. You could use different load files for different projects, domains, or contexts, and define aliases or one line scripts to give them meaningful names. For example, if you had Ansible helper code in `~/projects/ansible-tools/rexe-ansible.rb`, you could define an alias in your startup script:

```bash
➜  ~   alias rxans="rexe -l ~/projects/ansible-tools/rexe-ansible.rb $*"
```
...and then you would have an Ansible DSL available for me to use by calling `rxans`.

In addition, since you can also call `pry` on the context of any object, you can provide a DSL in a [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) (shell) trivially easily. Just to illustrate, here's how you would open a REPL on the File class:

```bash
➜  ~   ruby -r pry -e File.pry
# or
➜  ~   rexe -r pry File.pry
```

`self` would evaluate to the `File` class, so you could call class methods using only their names:

```bash
➜  ~   rexe -r pry File.pry
```
```
[6] pry(File)> size '/etc/passwd'
6804
[7] pry(File)> directory? '.'
true
[8] pry(File)> file?('/etc/passwd')
true
```

This could be really handy if you call `pry` on a custom object that has methods especially suited to your task:

```bash
➜  ~   rexe -r wifi-wand,pry  WifiWand::MacOsModel.new.pry
```
```
[1] pry(#<WifiWand::MacOsModel>)> random_mac_address
"a1:ea:69:d9:ca:05"
[2] pry(#<WifiWand::MacOsModel>)> connected_network_name
"My WiFi"
```

Ruby is supremely well suited for DSL's since it does not require parentheses for method calls, so calls to your custom methods _look_ like built in language commands and keywords. 


### Quotation Marks and Quoting Strings in Your Ruby Code

One complication of using utilities like rexe where Ruby code is specified on the command line is that you need to be careful about the shell's special treatment of certain characters. For this reason, it is often necessary to quote the Ruby code. You can use single or double quotes to have the shell treat your source code as a single argument. An excellent reference for how they differ is on StackOverflow at https://stackoverflow.com/questions/6697753/difference-between-single-and-double-quotes-in-bash.

Personally, I find single quotes more useful since I usually don't want special characters in my Ruby code like `$` to be processed by the shell.

Sometimes it doesn't matter:

```bash
➜  ~   rexe 'puts "hello"'
hello
➜  ~   rexe "puts 'hello'"
hello
```

We can also use `%q` or `%Q`, and sometimes this eliminates the needs for the outer quotes altogether:

```bash
➜  ~   rexe puts %q{hello}
hello
➜  ~   rexe puts %Q{hello}
hello
```

Sometimes the quotes to use on the outside (quoting your command in the shell) need to be chosen based on which quotes are needed on the inside. For example, in the following command, we need double quotes in Ruby in order for interpolation to work, so we use single quotes on the outside:

```bash
➜  ~   rexe puts '"The time is now #{Time.now}"'
```
```
The time is now 2019-03-29 16:41:26 +0800
```

In this case we also need to use single quotes on the outside, because we need literal double quotes in a `%Q{}` expression:

```bash
➜  ~   rexe 'puts %Q{The operating system name is "#{`uname`.chomp}".}'
```
```
The operating system name is "Darwin".
```

We can eliminate the need for any quotes in the Ruby code using `%Q{}`:

```bash
➜  ~   rexe puts '%Q{The time is now #{Time.now}}'
```
```
The time is now 2019-03-29 17:06:13 +0800
```

Of course you can always escape the quotes with backslashes instead, but that is probably more difficult to read.


### No Op Mode

The `-n` no-op mode will result in the specified source code _not_ being executed. This can sometimes be handy in conjunction with a `-g` (logging) option, if you have are building a rexe command and want to inspect the configuration options before executing the Ruby code.


### Mimicking Method Arguments

You may want to support arguments in your rexe commands. It's a little kludgy, but you could do this by piping in the arguments as rexe's stdin.

One of the previous examples downloaded currency conversion rates. To prepare for an example of how to do this, let's find out the available currency codes:

```bash
➜  /   echo $EUR_RATES_JSON | \
rexe -ij -mb -op "self['rates'].keys.sort.join(' ')"
```
```
AUD BGN BRL CAD CHF CNY CZK DKK GBP HKD HRK HUF IDR ILS INR ISK JPY KRW MXN MYR NOK NZD PHP PLN RON RUB SEK SGD THB TRY USD ZAR
```

The codes output are the legal arguments that could be sent to rexe's stdin as an argument in the command below. Let's find out the Euro exchange rate for _PHP_, Philippine Pesos:
 
```bash
➜  ~   echo PHP | rexe -ml -op -rjson \
        "rate = JSON.parse(ENV['EUR_RATES_JSON'])['rates'][self];\
        %Q{1 EUR = #{rate} #{self}}"

1 EUR = 58.986 PHP
```

In this code, `self` is the currency code `PHP` (Philippine Peso). We have accessed the JSON text to parse from the environment variable we previously populated.

Because we "used up" stdin for the `PHP` argument, we needed to read the JSON data explicitly from the environment variable, and that made the command more complex. A regular Ruby script would handle this more nicely.
 

### Using the Clipboard for Text Processing

For editing text in an editor, rexe can be used for text transformations that would otherwise need to be done manually.

The system's commands for pasting to and copying from the clipboard can handle the moving of the text between the editor and rexe. On the Mac, we have the following commands:
 
* `pbcopy` - copies the content of its stdin _to_ the clipboard
* `pbpaste` - copies the content _from_ the clipboard to its stdout
 
Let's say we have the following currency codes displayed on the screen (data abridged for brevity):

```
AUD BGN BRL PHP TRY USD ZAR
```

...and we want to turn them into Ruby symbols for inclusion in Ruby source code as keys in a hash whose values will be the display names of the currencies, e.g "Australian Dollar").

We could manually select that text and use system menu commands or keys to copy it to the clipboard, or we could do this:

```bash
➜  ~   echo AUD BGN BRL PHP TRY USD ZAR | pbcopy
```

After copying this line to the clipboard, we could run this:

```bash
➜  ~   pbpaste | rexe -ml -op \
        "split.map(&:downcase).map { |s| %Q{    #{s}: '',} }.join(%Q{\n})"
    aud: '',
    bgn: '',
    brl: '',
    # ...
```

If I add `| pbcopy` to the rexe command, then that output text would be copied into the clipboard instead of displayed in the terminal, and I could then paste it into my editor.

Using the clipboard in manual operations is handy, but using it in automated scripts is a very bad idea, since there is only one clipboard per user session. If you use the clipboard in an automated script you risk an error situation if its content is changed by another process, or, conversely, you could mess up another process when you change the content of the clipboard. 

### Multiline Ruby Commands

Although rexe is cleanest with short one liners, you may want to use it to include nontrivial Ruby code in your shell script as well. If you do this, you may need to add trailing backslashes to the lines of Ruby code.

What might not be so obvious is that you will often need to use semicolons as statement separators. For example, here is an example without a semicolon:

```bash
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m} \
puts to_a"
```
```
rexe: (eval):1: syntax error, unexpected tIDENTIFIER, expecting '}'
...new { print %Q{\u001b[33m} puts to_a }
...                           ^~~~
```

The shell combines all backslash terminated lines into a single line of text, so when the Ruby interpreter sees your code, it's all in a single line:

```bash
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m} puts to_a"
```

Adding the semicolon fixes the problem:

```bash
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m}; \
puts to_a"
```
```
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```


### Clearing the Require and Load Lists

There may be times when you have specified a load or require on the command line or in the `REXE_OPTIONS` environment variable, but you want to override it for a single invocation. Here are your options:
 
1) Unspecify _all_ the requires or loads with the `-r!` and `-l!` command line options, respectively.

2) Unspecify individual requires or loads by preceding the name with `-`, e.g. `-r -rails`. Array subtraction is used, and array subtraction removes _all_ occurrences of each element of the subtracted (subtrahend) array, so:

```bash
➜  ~   rexe -n -r rails,rails,rails,-rails -gP
...
   :requires=>["pp"],
...
```

...would show that the final `-rails` cancelled all the previous `rails` specifications.

We could have also extracted the requires list programmatically using `$RC` (described above) by doing this:

```bash
➜  ~   rexe -oP -r rails,rails,rails,-rails '$RC[:options][:requires]'
["pp"]
```    


### Clearing _All_ Options

You can also clear _all_ options specified up to a certain point in time with the _clear options_ option (`-c`). This is especially useful if you have specified options in the `REXE_OPTIONS` environment variable, and want to ignore all of them.


### Comma Separated Requires and Loads

For consistency with the `ruby` interpreter, rexe supports requires with the `-r` option, but also allows grouping them together using commas:

```bash
                                    vvvvvvvvvvvvvvvvvvvvv
➜  ~   echo $EUR_RATES_JSON | rexe -r json,awesome_print 'ap JSON.parse(STDIN.read)'
                                    ^^^^^^^^^^^^^^^^^^^^^
```

Files loaded with the `-l` option are treated the same way.


### Beware of Configured Requires

Requiring gems and modules for _all_ invocations of rexe will make your commands simpler and more concise, but will be a waste of execution time if they are not needed. You can inspect the execution times to see just how much time is being consumed. For example, we can find out that rails takes about 0.63 seconds to load on one system by observing and comparing the execution times with and without the require (output has been abbreviated using `grep`):

```bash
➜  ~   rexe -gy -r rails 2>&1 | grep duration
:duration_secs: 0.660138
➜  ~   rexe -gy          2>&1 | grep duration
:duration_secs: 0.027781
```
(For the above to work, the `rails` gem and its dependencies need to be installed.)


### Operating System Support

Rexe has been tested successfully on Mac OS, Linux, and Windows Subsystem for Linux (WSL). It is intended as a tool for the Unix shell, and, as such, no attempt is made to support Windows non-Unix shells.


### More Examples

Here are some more examples to illustrate the use of rexe.

----

#### Using Rexe as a Simple Calculator

To output the result to stdout, you can either call `puts` or specify the `-op` option:

```bash
➜  ~   rexe puts 1 / 3.0
0.3333333333333333
```

or:

```bash
➜  ~   rexe -op 1 / 3.0
0.3333333333333333
```

Since `*` is interpreted by the shell, if we do multiplication, we need to quote the expression:

```bash
➜  ~   rexe -op '2 * 7'
14
```

Of course, if you put the `-op` in the `REXE_OPTIONS` environment variable, you don't need to be explicit about the output:

```bash
➜  ~   export REXE_OPTIONS=-op
➜  ~   rexe '2 * 7'
14
```

----


#### Outputting ENV

Output the contents of `ENV` using AwesomePrint [see footnote ^4 regarding ENV.to_s]:

```bash
➜  ~   rexe -oa ENV
```
```
{
...
  "LANG" => "en_US.UTF-8",
   "PWD" => "/Users/kbennett/work/rexe",
 "SHELL" => "/bin/zsh",
...
}
```

----

#### Reformatting a Command's Output

Show disk space used/free on a Mac's main hard drive's main partition:

```bash
➜  ~   df -h | grep disk1s1 | rexe -ml \
"x = split; puts %Q{#{x[4]} Used: #{x[2]}, Avail: #{x[3]}}"
91% Used: 412Gi, Avail: 44Gi
```

(Note that `split` is equivalent to `self.split`, and because the `-ml` option is used, `self` is the line of text.

----

#### Formatting for Numeric Sort
    
Show the 3 longest file names of the current directory, with their lengths, in descending order:

```bash
➜  ~   ls  | rexe -ml -op "%Q{[%4d] %s} % [length, self]" | sort -r | head -3
[  50] Agoda_Booking_ID_9999999 49_–_RECEIPT_enclosed.pdf
[  40] 679a5c034994544aab4635ecbd50ab73-big.jpg
[  28] 2018-abc-2019-01-16-2340.zip
```

When you right align numbers using printf formatting, sorting the lines alphabetically will result in sorting them numerically as well.

----

#### Print yellow (trust me!):

This uses an [ANSI escape code](https://en.wikipedia.org/wiki/ANSI_escape_code) to output text to the terminal in yellow:

```bash
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m}; puts to_a"
➜  ~     # or
➜  ~   cowsay hello | rexe -mb "print %Q{\u001b[33m}; puts self"
➜  ~     # or
➜  ~   cowsay hello | rexe "print %Q{\u001b[33m}; puts STDIN.read"
```
```
  _______
 < hello >
  -------
         \   ^__^
          \  (oo)\_______
             (__)\       )\/\
                 ||----w |
                 ||     ||`
```


----

#### More YouTube: Differentiating Success and Failure 

Let's take the YouTube example from the "Loading Files" section further. Let's have the video that loads be different for the success or failure of the command.

If we put this in a load file (such as ~/.rexerc):

```ruby
def play(piece_code)
  pieces = {
    hallelujah: "https://www.youtube.com/watch?v=IUZEtVbJT5c&t=0m20s",
    rick_roll:  "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=0m43s",
    valkyries:  "http://www.youtube.com/watch?v=P73Z6291Pt8&t=0m28s",
    wm_tell:    "https://www.youtube.com/watch?v=j3T8-aeOrbg",
  }
  `open #{Shellwords.escape(pieces.fetch(piece_code))}`
end


def play_result(success)
  play(success ? :hallelujah : :rick_roll)
end


# Must pipe the exit code into this Ruby process, 
# e.g. using `echo $? | rexe play_result_by_exit_code`
def play_result_by_exit_code
  play_result(STDIN.read.chomp == '0')
end
```

Then when we issue a command that succeeds, the Hallelujah Chorus is played [see footnote ^2]:

```bash
➜  ~   uname; echo $? | rexe play_result_by_exit_code
```

...but when the command fails, in this case, with an executable which is not found, it plays Rick Astley's "Never Gonna Give You Up":

```bash
➜  ~   uuuuu; echo $? | rexe play_result_by_exit_code
```

----

#### Reformatting Source Code for Help Text

Another formatting example...I wanted to reformat this source code...

```ruby
         'i' => Inspect
         'j' => JSON
         'J' => Pretty JSON
         'n' => No Output
         'p' => Puts (default)
         's' => to_s
         'y' => YAML
```

...into something more suitable for my help text. Admittedly, the time it took to do this with rexe probably exceeded the time to do it manually, but it was an interesting exercise and made it easy to try different formats. Here it is, after copying the original text to the clipboard:

```bash
➜  ~   pbpaste | rexe -ml -op "sub(%q{'}, '-o').sub(%q{' =>}, %q{ })"
         -oi  Inspect
         -oj  JSON
         -oJ  Pretty JSON
         -on  No Output
         -op  Puts (default)
         -os  to_s
         -oy  YAML
```         
         

----

#### Currency Conversion

I travel a lot, and when I visit a country for the first time I often get confused by the exchange rate. I put this in my `~/.rexerc`:

```ruby
# Conversion rate to US Dollars
module Curr
  module_function
  def myr;      4.08  end  # Malaysian Ringits
  def thb;     31.72  end  # Thai Baht
  def usd;      1.00  end  # US Dollars
  def vnd;  23199.50  end  # Vietnamese Dong
end
```

If I'm lucky enough to be at my computer when I need to do a conversion, for example, to find the value of 150 Malaysian ringits in US dollars, I can do this:

```bash
➜  rexe git:(master) ✗   rexe puts 150 / Curr.myr
36.76470588235294
```

Obviously rates will change over time, but this will give me a general idea, which is usually all I need.


----

#### Reformatting Grep Output

I was recently asked to provide a schema for the data in my `rock_books` accounting gem. `rock_books` data is intended to be very small in size, and no data base is used. Instead, the input data is parsed on every run, and reports generated on demand. However, there are data structures (actually class instances) in memory at runtime, and their classes inherit from `Struct`. The definition lines look like this one:
 
```ruby
class JournalEntry < Struct.new(:date, :acct_amounts, :doc_short_name, :description, :receipts)
```

The `grep` command line utility prepends each of these matches with a string like this:

```
lib/rock_books/documents/journal_entry.rb:
```

So this is what worked well for me:

```bash
➜  ~   grep Struct **/*.rb | grep -v OpenStruct | rexe -ml -op \
"a =                            \
 gsub('lib/rock_books/', '')    \
.gsub('< Struct.new',    '')    \
.gsub('; end',           '')    \
.split('.rb:')                  \
.map(&:strip);                  \
                                \
%q{%-40s %-s} % [a[0] + %q{.rb}, a[1]]"
```

...which produced this output:

``` 
cmd_line/command_line_interface.rb       class Command (:min_string, :max_string, :action)
documents/book_set.rb                    class BookSet (:run_options, :chart_of_accounts, :journals)
documents/journal.rb                     class Entry (:date, :amount, :acct_amounts, :description)
documents/journal_entry.rb               class JournalEntry (:date, :acct_amounts, :doc_short_name, :description, :receipts)
documents/journal_entry_builder.rb       class JournalEntryBuilder (:journal_entry_context)
reports/report_context.rb                class ReportContext (:chart_of_accounts, :journals, :page_width)
types/account.rb                         class Account (:code, :type, :name)
types/account_type.rb                    class AccountType (:symbol, :singular_name, :plural_name)
types/acct_amount.rb                     class AcctAmount (:date, :code, :amount, :journal_entry_context)
types/journal_entry_context.rb           class JournalEntryContext (:journal, :linenum, :line)
``` 

Although there's a lot going on in this code, the vertical and horizontal alignments and spacing make the code straightforward to follow. Here's what it does:

* grep the code base for `"Struct"`
* exclude references to `"OpenStruct"` with `grep -v`
* remove unwanted text with `gsub`
* split the line into 1) a filespec relative to `lib/rockbooks`, and 2) the class definition
* strip unwanted space because that will mess up the horizontal alignment of the output.
* use C-style printf formatting to align the text into two columns

----

 
### Conclusion

Rexe is not revolutionary technology, it's just plumbing that removes parsing, formatting, and low level configuration from your command line so that you can focus on the high level task at hand.

When we consider a new piece of software, we usually think "what would this be helpful with now?". However, for me, the power of rexe is not so much what I can do with it in a single use case now, but rather what will I be able to do over time as I accumulate more experience and expertise with it.

I suggest starting to use rexe even for modest improvements in workflow, even if it doesn't seem compelling. There's a good chance that as you use it over time, new ideas will come to you and the workflow improvements will increase exponentially.

A word of caution though -- the complexity and difficulty of _sharing_ your rexe scripts across systems will be proportional to the extent to which you use environment variables and loaded files for configuration and shared code. Be responsible and disciplined in making this configuration and code as clean and organized as possible.

----

#### Footnotes

[1]: Rexe is an embellishment of the minimal but excellent `rb` script at https://github.com/thisredone/rb. I started using `rb` and thought of lots of other features I would like to have, so I started working on rexe.

[2]: It's possible that when this page opens in your browser it will not play automatically. You may need to change your default browser, or change the code that opens the URL. Firefox's new (as of March 2019) version 66 suppresses autoplay; you can register exceptions to this policy: open Firefox Preferences, search for "autoplay" and add "https://www.youtube.com".
 
[3]: Making this truly OS-portable is a lot more complex than it looks on the surface. On Linux, `xdg-open` may not be installed by default. Also, Windows Subsystem for Linux (WSL) out of the box is not able to launch graphical applications.

Here is a _start_ at a method that opens a resource portably across operating systems:

```ruby
  def open_resource(resource_identifier)
    command = case (`uname`.chomp)
    when 'Darwin'
      'open'
    when 'Linux'
      'xdg-open'
    else
      'start'
    end

    `#{command} #{resource_identifier}`
  end
```

[4]: It is an interesting quirk of the Ruby language that `ENV.to_s` returns `"ENV"` and not the contents of the `ENV` object. As a result, many of the other output formats will also return some form of `"ENV"`. You can handle this by specifying `ENV.to_h`.
