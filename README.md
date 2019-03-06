---
title: The `rexe` Command Line Executor and Filter
date: 2019-02-15
---

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
➜  ~   echo $EUR_RATES_JSON | ruby -r json -r awesome_print -e 'ap JSON.parse(STDIN.read)'
{
    "rates" => {
        "MXN" => 21.781,
        ...
        "DKK" => 7.462
    },
     "base" => "EUR",
     "date" => "2019-02-22"
}
```

However, the configuration setup (the `require`s) make the command long and tedious, discouraging this
approach.

### Rexe

Enter the `rexe` script. [^1]
 
`rexe` is at https://github.com/keithrbennett/rexe and can be installed with
`gem install rexe`. `rexe` provides several ways to simplify Ruby on the command
line, tipping the scale so that it is practical to do it more often.

Here is `rexe`'s help text as of the time of this writing:

```
rexe -- Ruby Command Line Executor/Filter -- v0.10.0 -- https://github.com/keithrbennett/rexe

Executes Ruby code on the command line, optionally taking standard input and writing to standard output.

Options:

-c  --clear_options        Clear all previous command line options specified up to now
-h, --help                 Print help and exit
-l, --load RUBY_FILE(S)    Ruby file(s) to load, comma separated, or ! to clear
-i, --input_mode MODE      Mode with which to handle input (i.e. what `self` will be in your code):
                           -il line mode; each line is ingested as a separate string
                           -ie enumerator mode
                           -ib big string mode; all lines combined into single multiline string
                           -in (default) no input mode; no special handling of input; self is not input 
-n, --[no-]noop            Do not execute the code (useful with -v); see note (1) below
-r, --require REQUIRES     Gems and built-in libraries to require, comma separated, or ! to clear
-v, --[no-]verbose         verbose mode (logs to stderr); see note (1) below

If there is an .rexerc file in your home directory, it will be run as Ruby code 
before processing the input.

If there is a REXE_OPTIONS environment variable, its content will be prepended to the command line
so that you can specify options implicitly (e.g. `export REXE_OPTIONS="-r awesome_print,yaml"`)

(1) For boolean 'verbose' and 'noop' options, the following are valid:
-v no, -v yes, -v false, -v true, -v n, -v y, -v +, but not -v -
```

For consistency with the `ruby` interpreter we called previously, `rexe` supports requires with the `-r` option, but as one tiny improvement it also allows grouping them together using commas:

```
                                    vvvvvvvvvvvvvvvvvvvvv
➜  ~   echo $EUR_RATES_JSON | rexe -r json,awesome_print 'ap JSON.parse(STDIN.read)'
                                    ^^^^^^^^^^^^^^^^^^^^^
```

This command produces the same results as the previous `ruby` one.

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
-i, --input_mode MODE      Mode with which to handle input (i.e. what `self` will be in your code):
                           -il line mode; each line is ingested as a separate string
                           -ie enumerator mode
                           -ib big string mode; all lines combined into single multiline string
                           -in (default) no input mode; no special handling of input; self is not input 
```

The first three are _filter_ modes; they make standard input available
to your code as `self`, and automatically output to standard output
the last value evaluated by your code.

The last (and default) is the _executor_ mode. It merely assists you in
executing the code you provide without any special implicit handling of standard input.


#### -il "Line" Filter Mode

In this mode, your code would be called once per line of input,
and in each call, `self` would evaluate to the line of text:

```
➜  ~   echo "hello\ngoodbye" | rexe -is reverse
olleh
eybdoog
```

`reverse` is implicitly called on each line of standard input.  `self`
 is the input line in each call (we could also have used `self.reverse` but the `self` would have been redundant.).
  

#### -ie "Enumerator" Filter Mode

In this mode, your code is called only once, and `self` is an enumerator
dispensing all lines of standard input. To be more precise, it is the enumerator returned by `STDIN.each_line`.

Dealing with input as an enumerator enables you to use the wealth of `Enumerable` methods such as `select`, `to_a`, `map`, etc.

Here is an example of using `-ie` to add line numbers to the first 3
files in the directory listing:

```
➜  ~   ls / | rexe -ie "first(3).each_with_index { |ln,i| puts '%5d  %s' % [i, ln] }; nil"

    0  AndroidStudioProjects
    1  Applications
    2  Desktop
```

Since `self` is an enumerable, we can call `first` and then `each_with_index`.


#### -ib "Big String" Filter Mode

In this mode, all standard input is combined into a single, (possibly)
large string, with newline characters joining the lines in the string.

A good example of when you would use this is when you parse JSON or YAML text; you need to pass the entire (probably) multiline string to the parse method.

An earlier example would be more simply specified using this mode, since `STDIN.read` could be replaced with `self`:

```
➜  ~   echo $EUR_RATES_JSON | rexe -ib -r awesome_print,json 'ap JSON.parse(self)'
```

#### -in "No Input" Executor Mode -- The Default

Examples up until this point have all used the default
`-in` mode. This is the simplest use case, where `self`
does not evaluate to anything useful, and if you cared about standard
input, you would have to code it yourself (e.g. as we did earlier with `STDIN.read`).


#### Filter Input Mode Memory Considerations

If you may have more input than would fit in memory, you can do the following:

* use `-il` (line) mode so you are fed only 1 line at a time
* use `-ie` (enumerator) mode or use `-in` (no input) mode with something like `STDIN.each_line`, 
but make sure not to call any methods (e.g. `map`, `select`)
 that will produce an array of all the input


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


#### Suppressing Automatic Output in Filter Modes

The filter input modes will automatically call `puts` to output the last evaulated value of your code to stdout. There may be times you may want to do something _else_ with the input and send nothing to stdout. For example, you might want to write something to a file, send to a network, etc. The simplest way to suppress output is to make nil or the empty string the final value in the expression. This can be accomplished simply merely by appending `; nil` or `;''` to your code. For example, to only output directory entries containing the letter 'e' in `-il` (line) mode:

```
# Output only entries that contain the letter 'e':
➜  /   ls | sort | rexe -il "include?('e') ? self : nil"

Incompatible Software

Network
...
```

However, as you can see, blank lines were displayed where `nil` was output. Why? Because in -il mode,
 puts will be called unconditionally on whatever value is the result of the expression. In the case of nil,
 puts outputs an empty string and its usual newline. This is probably not what you want.

If you want to see the `nil`s, you could replace `nil` with `nil.inspect`, which returns the string `'nil'`,
 unlike `nil.to_s` which returns the empty string. Of course, 
 there may be some other custom string you would want, 
 such as `[no match]` or `-`, or you could just specify the string `'nil'`. [^2]

But you probably don't want any line at all to display for excluded objects. For this it is best to use 
`-ie` (enumerator) mode. If you won't have a huge amount of input data you could use `select`:

```
# Output only entries that contain the letter 'e':
➜  /   ls | sort | rexe -ie "select { |s| s.include?('e') }"
Incompatible Software
Network
System
```

Here, `select` returns an array which is implicitly passed to `puts`. `puts` does _not_ call `to_s` when passed an array, but instead has special handling for arrays which prints each element on its own line. If instead we appended `.to_s` 
or `.inspect` to the result array, we would get the more compact array notation: 
 
```
➜  /   ls | sort | rexe -ie "select { |s| s.include?('e') }.to_s"
["Incompatible Software\n", "Network\n", ..., "private\n"]
```

#### Quoting Strings in Your Ruby Code

One complication of using utilities like `rexe` where Ruby code is specified on the shell command line is that
you need to be careful about the shell's special treatment of certain characters. For this reason, it is often
necessary to quote the Ruby code. You can use single or double quotes. 
An excellent reference for how they differ is [here](https://stackoverflow.com/questions/6697753/difference-between-single-and-double-quotes-in-bash).

Feel free to fall back on Ruby's super useful `%q{}` and `%Q{}`, equivalent to single and double quotes, respectively.


#### Mimicking Method Arguments

You may want to support arguments in your code. One of the previous examples downloaded currency conversion rates. Let's find out the available currency codes:

```
➜  /   echo $JSON_TEXT | rexe -rjson -ib \
        "JSON.parse(self)['rates'].keys.sort.join(' ')"
AUD BGN BRL CAD CHF CNY CZK DKK GBP HKD HRK HUF IDR ILS INR ISK JPY KRW MXN MYR NOK NZD PHP PLN RON RUB SEK SGD THB TRY USD ZAR
```
 
 Here would be a way to output a single rate:
 
```
➜  ~   echo PHP | rexe -il -rjson \
        "rate = JSON.parse(ENV['EUR_RATES_JSON'])['rates'][self];\
        %Q{1 EUR = #{rate} #{self}}"

1 EUR = 58.986 PHP
```

In this code, `self` is the currency code `PHP` (Philippine Peso). We have accessed the JSON text to parse from the environment variable we previously populated.


### More Examples

Here are some more examples to illustrate the use of `rexe`.

----

Show disk space used/free on a Mac's main hard drive's main partition:

```
➜  ~   df -h | grep disk1s1 | rexe -il \
"x = split; puts %Q{#{x[4]} Used: #{x[2]}, Avail #{x[3]}}"
91% Used: 412Gi, Avail 44Gi
```

(Note that `split` is equivalent to `self.split`, and because the `-il` option is used, `self` is the line of text.

----

Print yellow (trust me!):

```
➜  ~   cowsay hello | rexe -ie "print %Q{\u001b[33m}; puts to_a"
➜  ~     # or
➜  ~   cowsay hello | rexe -ib "print %Q{\u001b[33m}; puts self"
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
➜  ~   ls  | rexe -il "%Q{[%4d] %s} % [length, self]" | sort -r | head -3
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
➜  ~   grep Struct **/*.rb | grep -v OpenStruct | rexe -il \
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

 



### Conclusion

`rexe` is not revolutionary technology, it's just plumbing that removes low level
configuration from your command line so that you can focus on the high level
task at hand.

When we think of a new piece of software, we usually think "what would this be
helpful with now?". However, the power of `rexe` is not so much what can be done
with it in a single use case now, but rather what will it do for me as I get
used to the concept and my supporting code and its uses evolve.

I suggest starting to use `rexe` even for modest improvements in workflow, even
if it doesn't seem compelling. There's a good chance that as you use it over
time, new ideas will come to you and the workflow improvements will increase
exponentially.


#### Footnotes

[^1]: `rexe` is an embellishment of the minimal but excellent `rb` script at
https://github.com/thisredone/rb. I started using `rb` and thought of lots of
other features I would like to have, so I started working on `rexe`.

[^2]: You might wonder why we don't just refrain from sending output to stdout on null or false. That is certainly easy to implement, but there are other ways to accomplish this (using _enumerable_ or _no input_ modes), and the lack of output might be surprising and disconcerting to the user. What do _you_ think, which approach makes more sense to you?
