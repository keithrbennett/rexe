## rexe -- Ruby Command Line Executor


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
