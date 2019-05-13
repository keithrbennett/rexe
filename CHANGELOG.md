## rexe -- Ruby Command Line Executor/Filter


### 1.2.0

* Add --project-url option to output project URL on Github, then exit


### 1.1.0

* Enable specifying different output formats for tty and block devices. (#4)
* Outputs exception text on error instead of just exception class.


### 1.0.3

* Fix/improve help text.


### 1.0.2

* Add mention of -v/--version to help text.


### 1.0.1

* Improve help text.
* Improve code block display in readme.


### 1.0.0

* Suppress help message on SystemExit.
* Eliminate stack trace from all error messages.
* Fix Awesome Print output to have a "\n" at the end of it.
* Add eur_rates.json sample data.
* Remove gem post-commit message.


### 0.15.1

* Fix help text in readme.


### 0.15.0

* Source code now defaults to 'self' (#3).
* Change parse errors to not output help text and stack trace, but instead a short message with suggestion to use -h.


### 0.14.0

* The default output format has been changed from -op (:puts) to -on (:none).
* Support automatic input from file with -f option.
* Normalize load filespecs to eliminate duplication and to facilitate correct deletion.


### v0.13.0

* Much refactoring.
* Allow omitting source code in no-op mode.
* Add ability to remove load or require files using minus sign preceding name.
* Requires needed for parsing and formatting will now be included in log output.
* Change license from MIT to Apache version 2.
* Add undocumented '--open-project' command line option to launch Github project page in Mac OS and possibly other OS's.
* Fix and add tests.


### v0.12.0

* Change verbose -v boolean option to log output format -g option.
* Print error message and exit with nonzero exit code if no source code provided.
* Add $RC.i alias for $RC.count.


### v0.11.0

* Make global $RC (Rexe Context) OpenStruct available to user code; added `count` for record count in `-ml` mode.
* Change verbose output to YAML format.
* Failure to load a file now raises an error.
* Add pretty print output format.
* Fix tests.


### v0.10.3

* Fix: parsing should not be attempted if in no input mode.
* Improve README.

### v0.10.2

* Fix problem in :none input format mode.


### v0.10.1

* Fix help text for input formats.


### v0.10.0

* Add input format option -i to simplify ingesting JSON, YAML, Marshal formats.
* Add Marshal output option.
* In -mn mode:
  * change output behavior; now outputs last evaluated value like other modes.
  * self is now a newly created object (Object.new), providing a clean slate for adding instance variables, methods, etc.
* Wrap execution in Bundler.with_clean_env to enable loading of gems not in Gemfile.


### v0.9.0

* Change -ms (single or separate string) mode to -ml (line) mode.
* Use article text for readme.


### v0.8.1

* Fix and improve help text.


### v0.8.0

* Add no-op mode to suppress execution of code (useful with -v).
* Add clear mode to clear all options specified up to that point (useful to ignore REXE_OPTIONS environment variable settings).

### v0.7.0

* Remove -u option to address issue #1.


### v0.6.1

* Improve handling of nonexistent load files (-l, -u options).


### v0.6.0

* Change default input mode from :string to :no_input.
* Improve readme.
* Add post install message warning about change of default input mode.


### v0.5.0

* Add '!' to require and load command options to clear respective file lists.
* In 'no input' mode (-mn), fix so that only output explicitly sent to stdout is output (unlike other modes).
* Gemspec now parses version from text instead of loading the script.
* Add tests.

### v0.4.1

* Fix -r (require) bug.


### v0.4.0

* Add -u option for loading files at current directory or above.
* Fix command line option handling for disabling verbose mode previously enabled.
* Improve README.


### v0.3.1

* Help text fixes.


### v0.3.0

* For consistency with requires, specifying multiple load files on the command line can be done
  with comma separated filespecs.


### v0.2.0

* Improve README and verbose logging.

### v0.1.0

* Add ability to handle input as a single multiline string (using -mb option).
* Add -mn mode for no input at all.
* Fix and improve usage examples in README.


### v0.0.2

* Fix running-as-script test.


### v0.0.1

* Initial version.
