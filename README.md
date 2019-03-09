---
title: The `rexe` Command Line Executor and Filter
date: 2019-02-15
---

[Caution: This is a long article! If you lose patience reading it, I suggest skimming the headings
and the source code, and at minimum, reading the Conclusion.]

I love the power of the command line, but not the awkwardness of shell scripting
languages. Sure, there's a lot that can be done with them, but it doesn't take
long before I get frustrated with their bluntness and verbosity.

Often, I solve this problem by writing a Ruby script instead. Ruby gives me fine
grained control in a "real" programming language with which I am comfortable.
However, when there are multiple OS commands to be called, then Ruby can be
awkward too.

### Using the Ruby Interpreter on the Command Line

Sometimes a good solution is to combine Ruby and shell scripting on the same
command line. Here's an example, using an intermediate environment variable to
simplify the logic and save the data for use by future commands.
An excerpt of the output follows the code:

```
➜  ~   export EUR_RATES_JSON=`curl https://api.exchangeratesapi.io/latest`
➜  ~   echo $EUR_RATES_JSON | ruby -r json -r yaml -e 'puts JSON.parse(STDIN.read).to_yaml'
---
rates:
  MXN: 21.96
  AUD: 1.5964
  HKD: 8.8092
  ...
base: EUR
date: '2019-03-08'
```

However, the configuration setup (the `require`s) along with the reading, parsing, and formatting
make the command long and tedious, discouraging this approach.

### Rexe

Enter the `rexe` script: [^1]

Among other things, `rexe` provides switch-activated input parsing and output formatting so that converting 
from one format to another is trivial.
This command does the same thing as the previous `ruby` command:

```
➜  ~   echo $EUR_RATES_JSON | rexe -mb -ij -oy self
```
 
`rexe` is at https://github.com/keithrbennett/rexe and can be installed with
`gem install rexe`. `rexe` provides several ways to simplify Ruby on the command
line, tipping the scale so that it is practical to do it more often.

Here is `rexe`'s help text as of the time of this writing:

```
rexe -- Ruby Command Line Executor/Filter -- v0.10.2 -- https://github.com/keithrbennett/rexe

Executes Ruby code on the command line, optionally taking standard input and writing to standard output.

rexe [options] 'Ruby source code'

Options:

-c  --clear_options        Clear all previous command line options specified up to now
-h, --help                 Print help and exit
-i, --input_format FORMAT  Input format (none is default)
                             -ij  JSON
                             -im  Marshal
                             -in  None
                             -iy  YAML
-l, --load RUBY_FILE(S)    Ruby file(s) to load, comma separated, or ! to clear
-m, --input_mode MODE      Mode with which to handle input (i.e. what `self` will be in your code):
                             -ml  line mode; each line is ingested as a separate string
                             -me  enumerator mode
                             -mb  big string mode; all lines combined into single multiline string
                             -mn  (default) no input mode; no special handling of input; self is an Object.new 
-n, --[no-]noop            Do not execute the code (useful with -v); see note (1) below
-o, --output_format FORMAT Output format (puts is default):
                             -oi  Inspect
                             -oj  JSON
                             -oJ  Pretty JSON
                             -om  Marshal
                             -on  No Output
                             -op  Puts (default)
                             -os  to_s
                             -oy  YAML
-r, --require REQUIRE(S)   Gems and built-in libraries to require, comma separated, or ! to clear
-v, --[no-]verbose         verbose mode (logs to stderr); see note (1) below

If there is an .rexerc file in your home directory, it will be run as Ruby code 
before processing the input.

If there is a REXE_OPTIONS environment variable, its content will be prepended to the command line
so that you can specify options implicitly (e.g. `export REXE_OPTIONS="-r awesome_print,yaml"`)

(1) For boolean 'verbose' and 'noop' options, the following are valid:
-v no, -v yes, -v false, -v true, -v n, -v y, -v +, but not -v -
```

### Simplifying the Rexe Invocation with Configuration

`rexe` provides two approaches to configuration:

* the `REXE_OPTIONS` environment variable
* loading Ruby files before executing the code using `-l`, or implicitly with `~/.rexerc`

These approaches enable removing configuration information from your `rexe` command,
making it shorter and simpler to read.


### The REXE_OPTIONS Environment Variable

The `REXE_OPTIONS` environment variable can contain command line options that would otherwise
be specified on the `rexe` command line:

```
➜  ~   export REXE_OPTIONS="-r json,awesome_print"
➜  ~   echo $EUR_RATES_JSON | rexe 'ap JSON.parse(STDIN.read)'
```

Like any environment variable, `REXE_OPTIONS` could also be set in your startup script, input on a command line using `export`, or in another script loaded with `source` or `.`.

### Loading Files

The environment variable approach works well for command line _options_, but what if we want to specify Ruby _code_ (e.g. methods) that can be used by multiple invocations of `rexe`?

For this, `rexe` lets you _load_ Ruby files, using the `-l` option, or implicitly (without your specifying it) in the case of the `~/.rexerc` file. Here is an example of something you might include in such a file (this is an alternate approach to specifying `-r` in the `REXE_OPTIONS` environment variable):

```
require 'json'
require 'yaml'
require 'awesome_print'
```

Requiring gems and modules for _all_ invocations of `rexe` will make your commands simpler and more concise, but will be a waste of execution time if they are not needed. You can inspect the execution times to see just how much time is being wasted. For example, we can find out that nokogiri takes about 0.7 seconds to load on my laptop by observing and comparing the execution times with and without the require (output has been abbreviated):

```
➜  ~   rexe -v
rexe time elapsed: 0.094946 seconds.

➜  ~   rexe -v -r nokogiri
rexe time elapsed: 0.165996 seconds.
```

### Using Loaded Files in Your Commands

Here's something else you could include in such a load file:

```
# Open YouTube to Wagner's "Ride of the Valkyries"
def valkyries
  `open "http://www.youtube.com/watch?v=P73Z6291Pt8&t=0m28s"`
end
```

Why would you want this? You might want to be able to go to another room until a long job completes, and be notified when it is done. The `valkyries` method will launch a browser window pointed to Richard Wagner's "Ride of the Valkyries" starting at a lively point in the music. (The `open` command is Mac specific and could be replaced with `start` on Windows, a browser command name, etc.) If you like this sort of thing, you could download public domain audio files and use a command like player like `afplay` on Mac OS, or `mpg123` or `ogg123` on Linux. This approach is lighter weight, requires no network access, and will not leave an open browser window for you to close.

Here is an example of how you might use this, assuming the above configuration is loaded from your `~/.rexerc` file or 
an explicitly loaded file:

```
➜  ~   tar czf /tmp/my-whole-user-space.tar.gz ~ ; rexe valkyries
```

You might be thinking that creating an alias or a minimal shell script for this open would be a simpler and more natural
approach, and I would agree with you. However, over time the number of these could become unmanageable, whereas using Ruby
you could build a pretty extensive and well organized library of functionality. Moreover, that functionality could be made available to _all_ your Ruby code (for example, by putting it in a gem), and not just command line one liners.

For example, you could have something like this in a configuration file:

```
def play(piece_code)
  pieces = {
    hallelujah: "https://www.youtube.com/watch?v=IUZEtVbJT5c&t=0m20s",
    valkyries:  "http://www.youtube.com/watch?v=P73Z6291Pt8&t=0m28s",
    wm_tell:    "https://www.youtube.com/watch?v=j3T8-aeOrbg"
    # ... and many, many more
  }
  `open #{Shellwords.escape(pieces.fetch(piece_code))}`
end
```

...which you could then call like this:

```
➜  ~   tar czf /tmp/my-whole-user-space.tar.gz ~ ; rexe 'play(:hallelujah)'
```

(You need to quote the `play` call because otherwise the shell will process and remove the parentheses.
Alternatively you could escape the parentheses with backslashes.)


### Clearing the Require and Load Lists

There may be times when you have specified a load or require on the command line
or in the `REXE_OPTIONS` environment variable,
but you want to override it for a single invocation. Currently you cannot
unspecify a single resource, but you can unspecify _all_ the requires or loads
with the `-r!` and `-l!` command line options, respectively.


### Clearing _All_ Options

You can also clear _all_ options specified up to a certain point in time with the _clear options_ option (`-c`).
This is especially useful if you have specified options in the `REXE_OPTIONS` environment variable, 
and want to ignore all of them.


### Verbose Mode

In addition to displaying the execution time, verbose mode will display the version, date/time of execution, source code
to be evaluated, options specified (by all approaches), and that the global file has been loaded (if it was found):
 
```
➜  ~   echo $EUR_RATES_JSON | rexe -v -rjson,awesome_print "ap JSON.parse(STDIN.read)"
rexe version 0.7.0 -- 2019-03-03 18:18:14 +0700
Source Code: ap JSON.parse(STDIN.read)
Options: {:input_mode=>:no_input, :loads=>[], :requires=>["json", "awesome_print"], :verbose=>true}
Loading global config file /Users/kbennett/.rexerc
...
rexe time elapsed: 0.085913 seconds.
``` 
 
This extra output is sent to standard error (_stderr_) instead of standard output
(_stdout_) so that it will not pollute the "real" data when stdout is piped to
another command.

If you would like to append this informational output to a file, you could do something like this:

```
➜  ~   rexe ... -v 2>>rexe.log
```

If verbose mode is enabled in configuration and you want to disable it, you can
do so by using any of the following: `--[no-]verbose`, `-v n`, or `-v false`.

### Input Modes

`rexe` tries to make it simple and convenient for you to handle standard input, 
and in different ways. Here is the help text relating to input modes:

```
-m, --input_mode MODE      Mode with which to handle input (i.e. what `self` will be in your code):
                           -ml line mode; each line is ingested as a separate string
                           -me enumerator mode
                           -mb big string mode; all lines combined into single multiline string
                           -mn (default) no input mode; no special handling of input; self is not input 
```

The first three are _filter_ modes; they make standard input available
to your code as `self`, and automatically output to standard output
the last value evaluated by your code.

The last (and default) is the _executor_ mode. It merely assists you in
executing the code you provide without any special implicit handling of standard input.


#### -ml "Line" Filter Mode

In this mode, your code would be called once per line of input,
and in each call, `self` would evaluate to the line of text:

```
➜  ~   echo "hello\ngoodbye" | rexe -ms reverse
olleh
eybdoog
```

`reverse` is implicitly called on each line of standard input.  `self`
 is the input line in each call (we could also have used `self.reverse` but the `self` would have been redundant.).
  
Be aware that although you can control the _content_ of output records, 
there is no way to selectively _exclude_ records from being output. Even if the result of the code
is nil or the empty string, a newline will be output. If this is an issue, you could do one of the following:
 
 * use Enumerator mode and call `select`, `filter`, `reject`, etc.
 * use the `-on` _no output_ mode and call `puts` explicitly for the output you _do_ want


#### -me "Enumerator" Filter Mode

In this mode, your code is called only once, and `self` is an enumerator
dispensing all lines of standard input. To be more precise, it is the enumerator returned by `STDIN.each_line`.

Dealing with input as an enumerator enables you to use the wealth of `Enumerable` methods such as `select`, `to_a`, `map`, etc.

Here is an example of using `-me` to add line numbers to the first 3
files in the directory listing:

```
➜  ~   ls / | rexe -me "first(3).each_with_index { |ln,i| puts '%5d  %s' % [i, ln] }; nil"

    0  AndroidStudioProjects
    1  Applications
    2  Desktop
```

Since `self` is an enumerable, we can call `first` and then `each_with_index`.


#### -mb "Big String" Filter Mode

In this mode, all standard input is combined into a single, (possibly
large) string, with newline characters joining the lines in the string.

A good example of when you would use this is when you parse JSON or YAML text; 
you need to pass the entire (probably) multiline string to the parse method. 
This is the mode that was used in the first `rexe` example in this article.


#### -mn "No Input" Executor Mode -- The Default

In this mode, no special handling of standard input is done at all;
if you want standard input you need to code it yourself (e.g. with `STDIN.read`).

`self` evaluates to a new instance of `Object`, which would be used 
if you defined methods, constants, instance variables, etc., in your code.


#### Filter Input Mode Memory Considerations

If you may have more input than would fit in memory, you can do the following:

* use `-ml` (line) mode so you are fed only 1 line at a time
* use an Enumerator, either by specifying the `-me` (enumerator) mode option,
 or using `-mn` (no input) mode in conjunction with something like `STDIN.each_line`. Then: 
  * Make sure not to call any methods (e.g. `map`, `select`)
 that will produce an array of all the input because that will pull all the records into memory, or:
  * use [lazy enumerators](https://www.honeybadger.io/blog/using-lazy-enumerators-to-work-with-large-files-in-ruby/)
 


### Output Formats

Several output formats are provided for your convenience. Here they are in alphabetical order:

* `-oa` (Awesome Print) - calls `.ai` on the object to get the string that `ap` would print
* `-oi` (Inspect) - calls `inspect` on the object
* `-oj` (JSON) - calls `to_json` on the object
* `-oJ` (Pretty JSON) calls `JSON.pretty_generate` with the object
* `-on` (No Output) - output is suppressed
* `-op` (Puts) - produces what `puts` would output
* `-os` (To String) - calls `to_s` on the object
* `-oy` (YAML) - calls `to_yaml` on the object

All formats will implicitly `require` anything needed to accomplish their task (e.g. `require 'yaml'`).

You may wonder why these formats are provided, given that their functionality 
could be included in the custom code instead. Here's why:

* The savings in command line length goes a long way to making these commands more readable and feasible.
* It's much simpler to use multiple formats, as there is no need to change the code itself. This also enables
parameterization of the output format.


### Implementing Domain Specific Languages (DSL's)

Defining methods in your loaded files enables you to effectively define a [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) for your command line use. You could use different load files for different projects, domains, or contexts, and define aliases or one line scripts to give them meaningful names. For example, if I wrote code to work with Ansible and put it in `~/projects/rexe-ansible.rb`, I could define an alias in my startup script:

```
➜  ~   alias rxans="rexe -l ~/projects/rexe-ansible.rb $*"
```
...and then I would have an Ansible DSL available for me to use by calling `rxans`.

In addition, since you can also call `pry` on the context of any object, you
can provide a DSL in a [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) (shell)
trivially easily. Just to illustrate, here's how you would open a REPL on the File class:

```
➜  ~   ruby -r pry -e File.pry
# or
➜  ~   rexe -r pry File.pry
```

`self` would evaluate to the `File` class, so you could call class methods implicitly using only their names:

```
➜  rock_books git:(master) ✗   rexe  -r pry File.pry

[6] pry(File)> size '/etc/passwd'
6804
[7] pry(File)> directory? '.'
true
[8] pry(File)> file?('/etc/passwd')
true
```

This could be really handy if you call `pry` on a custom object that has methods especially suited to your task.

Ruby is supremely well suited for DSL's since it does not require parentheses for method calls, 
so calls to your custom methods _look_ like built in language commands and keywords. 


### Quoting Strings in Your Ruby Code

One complication of using utilities like `rexe` where Ruby code is specified on the shell command line is that
you need to be careful about the shell's special treatment of certain characters. For this reason, it is often
necessary to quote the Ruby code. You can use single or double quotes to have the shell treat your source code
as a single argument. 
An excellent reference for how they differ is [here](https://stackoverflow.com/questions/6697753/difference-between-single-and-double-quotes-in-bash).

Feel free to fall back on Ruby's super useful `%q{}` and `%Q{}`, equivalent to single and double quotes, respectively.


### Mimicking Method Arguments

You may want to support arguments in your code. One of the previous examples downloaded currency conversion rates. Let's find out the available currency codes:

```
➜  /   echo $EUR_RATES_JSON | rexe -rjson -mb \
        "JSON.parse(self)['rates'].keys.sort.join(' ')"
AUD BGN BRL CAD CHF CNY CZK DKK GBP HKD HRK HUF IDR ILS INR ISK JPY KRW MXN MYR NOK NZD PHP PLN RON RUB SEK SGD THB TRY USD ZAR
```
 
 Here would be a way to output a single rate:
 
```
➜  ~   echo PHP | rexe -ml -rjson \
        "rate = JSON.parse(ENV['EUR_RATES_JSON'])['rates'][self];\
        %Q{1 EUR = #{rate} #{self}}"

1 EUR = 58.986 PHP
```

In this code, `self` is the currency code `PHP` (Philippine Peso). We have accessed the JSON text to parse from the environment variable we previously populated.


### Using the Clipboard for Text Processing

Sometimes when editing text I need to do some one off text manipulation.
Using the system's commands for pasting to and copying from the clipboard,
this can easily be done. On the Mac, the `pbpaste` command outputs to stdout
the clipboard content, and the `pbcopy` command copies its stdin to the clipboard.

Let's say I have the following currency codes displayed on the screen:

```
AUD BGN BRL CAD CHF CNY CZK DKK GBP HKD HRK HUF IDR ILS INR ISK JPY KRW MXN MYR NOK NZD PHP PLN RON RUB SEK SGD THB TRY USD ZAR
```

...and I want to turn them into Ruby symbols for inclusion in Ruby source code as keys in a hash
whose values will be the display names of the currencies, e.g "Australian Dollar").
After copying this line to the clipboard, I could run this:

```
➜  ~   pbpaste | rexe -ml "split.map(&:downcase).map { |s| %Q{    #{s}: '',} }.join(%Q{\n})"
    aud: '',
    bgn: '',
    brl: '',
    # ...
```

If I add `| pbcopy` to the rexe command, then that output text would be copied into the clipboard instead of
displayed in the terminal, and I could then paste it in my editor.


### Multiline Ruby Commands

Although `rexe` is cleanest with short one liners, you may want to use it to include nontrivial Ruby code
in your shell script as well. If you do this, you may need to:

* add trailing backslashes to lines of Ruby code
* use %q{} and %Q{} in your Ruby code instead of single and double quotes, 
  since the quotes have special meaning to the shell


### The Use of Semicolons

You will probably find yourself using semicolons much more often than usual when you use `rexe`.
Obviously you would need them to separate statements on the same line:

```
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m}; puts to_a"
```

What might not be so obvious is that you _also_ need them if each statement is on its own line.
For example, here is an example without a semicolon:

```
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m} \
puts to_a"

/Users/kbennett/.rvm/gems/ruby-2.6.0/gems/rexe-0.10.1/exe/rexe:256:in `eval':
   (eval):1: syntax error, unexpected tIDENTIFIER, expecting '}' (SyntaxError)
...new { print %Q{\u001b[33m} puts to_a }
...                           ^~~~
```

The shell combines all backslash terminated lines into a single line of text, so when the Ruby
interpreter sees your code, it's all in a single line. Adding the semicolon fixes the problem:

```
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m}; \
puts to_a"

eval_context_object: #<Enumerator:0x00007f92b1972840>
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```


### Comma Separated Requires and Loads

For consistency with the `ruby` interpreter, `rexe` supports requires with the `-r` option, but 
also allows grouping them together using commas:

```
                                    vvvvvvvvvvvvvvvvvvvvv
➜  ~   echo $EUR_RATES_JSON | rexe -r json,awesome_print 'ap JSON.parse(STDIN.read)'
                                    ^^^^^^^^^^^^^^^^^^^^^
```

Files loaded with the `-l` option are treated the same way.

### More Examples

Here are some more examples to illustrate the use of `rexe`.

----

Show disk space used/free on a Mac's main hard drive's main partition:

```
➜  ~   df -h | grep disk1s1 | rexe -ml \
"x = split; puts %Q{#{x[4]} Used: #{x[2]}, Avail #{x[3]}}"
91% Used: 412Gi, Avail 44Gi
```

(Note that `split` is equivalent to `self.split`, and because the `-ml` option is used, `self` is the line of text.

----

Print yellow (trust me!):

```
➜  ~   cowsay hello | rexe -me "print %Q{\u001b[33m}; puts to_a"
➜  ~     # or
➜  ~   cowsay hello | rexe -mb "print %Q{\u001b[33m}; puts self"
➜  ~     # or
➜  ~   cowsay hello | rexe "print %Q{\u001b[33m}; puts STDIN.read"
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

    
Show the 3 longest file names of the current directory, with their lengths, in descending order:

```
➜  ~   ls  | rexe -ml "%Q{[%4d] %s} % [length, self]" | sort -r | head -3
[  50] Agoda_Booking_ID_9999999 49_–_RECEIPT_enclosed.pdf
[  40] 679a5c034994544aab4635ecbd50ab73-big.jpg
[  28] 2018-abc-2019-01-16-2340.zip
```

Notice that when you right align numbers using printf formatting, sorting the lines
alphabetically will result in sorting them numerically as well.

----

I was recently asked to provide a schema for the data in my `rock_books` accounting gem. `rock_books` data is intended to be very small in size, and no data base is used. Instead, the input data is parsed on every run, and reports generated on demand. However, there are data structures (actually class instances) in memory at runtime, and their classes inherit from `Struct`.
 The definition lines look like this one:
 
```
class JournalEntry < Struct.new(:date, :acct_amounts, :doc_short_name, :description, :receipts)
```

The `grep` command line utility prepends each of these matches with a string like this:

```
lib/rock_books/documents/journal_entry.rb:
```

So this is what worked well for me:

```
➜  ~   grep Struct **/*.rb | grep -v OpenStruct | rexe -ml \
"a = \
 gsub('lib/rock_books/', '')\
.gsub('< Struct.new',    '')\
.gsub('; end',           '')\
.split('.rb:')\
.map(&:strip);\
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

Although there's a lot going on here, the vertical and horizontal alignments and spacing make the code
straightforward to follow. Here's what it does:

* grep the code base for `"Struct"`
* exclude references to `"OpenStruct"` with `grep -v`
* remove unwanted text with `gsub`
* split the line into 1) a filespec relative to `lib/rockbooks`, and 2) the class definition
* strip unwanted space because that will mess up the horizontal alignment of the output.
* use C-style printf formatting to align the text into two columns

 
----

Let's go a little crazy with the YouTube example.
Let's have the video that loads be different for the success or failure
of the command.

If I put this in a load file (such as ~/.rexerc):

```
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


def play_result_by_exit_code
  play_result(STDIN.read.chomp == '0')
end

```

Then when I issue a command that succeeds, the Hallelujah Chorus is played:

```
➜  ~   uname; echo $? | rexe play_result_by_exit_code
```

...but when the command fails, in this case, with an executable which is not found, it plays Rick Astley's
"Never Gonna Give You Up":

```
➜  ~   uuuuu; echo $? | rexe play_result_by_exit_code
```

----

Another formatting example...I wanted to reformat this help text:

```
                                 'i' => Inspect
                                 'j' => JSON
                                 'J' => Pretty JSON
                                 'n' => No Output
                                 'p' => Puts (default)
                                 's' => to_s
                                 'y' => YAML
```

Admittedly, the time it took to do this with rexe probably exceeded the time to do it manually,
but it was an interesting exercise and made it easy to try different formats. Here it is:

```
➜  ~   pbpaste | rexe -ml "sub(%q{'}, '-o').sub(%q{' =>}, %q{ })"
                                 -oi  Inspect
                                 -oj  JSON
                                 -oJ  Pretty JSON
                                 -on  No Output
                                 -op  Puts (default)
                                 -os  to_s
                                 -oy  YAML
```                                 
                                 


### Conclusion

`rexe` is not revolutionary technology, it's just plumbing that removes low level
configuration from your command line so that you can focus on the high level
task at hand.

When we think of a new piece of software, we usually think "what would this be
helpful with now?". However, for me, the power of `rexe` is not so much what I can do
with it in a single use case now, but rather what will I be able to do with it over time
as I get used to the concept and my supporting code and its uses evolve.

I suggest starting to use `rexe` even for modest improvements in workflow, even
if it doesn't seem compelling. There's a good chance that as you use it over
time, new ideas will come to you and the workflow improvements will increase
exponentially.

A word of caution though -- 
the complexity and difficulty of sharing your `rexe` scripts across systems
will be proportional to the extent to which you use environment variables
and loaded files for configuration and shared code.
Be responsible and disciplined in making this configuration as organized as possible.

#### Footnotes

[^1]: `rexe` is an embellishment of the minimal but excellent `rb` script at
https://github.com/thisredone/rb. I started using `rb` and thought of lots of
other features I would like to have, so I started working on `rexe`.

[^2]: You might wonder why we don't just refrain from sending output to stdout on null or false. That is certainly easy to implement, but there are other ways to accomplish this (using _enumerable_ or _no input_ modes), and the lack of output might be surprising and disconcerting to the user. What do _you_ think, which approach makes more sense to you?
