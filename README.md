# BarmanCheck

Provides a command-line tool to run Barman (Backup and Recovery Manager for PostgreSQL)
"check" and "list" commands. It currently generates output in check_mk (Nagios) format, but 
can be easily extended for StatsD/Graphite, Elasticsearch, etc.
It is designed to call "barman check [dbname]" and "barman list [dbname] for the database
specified on the command line.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'barman_check'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barman_check

## Usage

After install, you can run barman_check --help to see available options. To test it out, use the
test output file, barman_output.txt, located in the spec/fixture directory, like so:

`cat spec/fixtures/barman_output.txt | barman_check`

Alternatively you can put the results of the barman commands into a file, separated by a line 
containing the word "FILE_DELIMITER" and `cat` the output and pipe it in. 
 
NOTE: the exe runs with the following default options -

backup age = 25 hours, backups = 3

These can be overridden using the command-line options, --bc and --ba.

To run in "realtime" mode, you will need to install barman, configure it to communicate
with your PostgreSQL database, and run barman_check as the barman user.
In this mode you must indicate your database name using the command-line
option --db=dbname, e.g. `barman_check --db=main`

All of the above modes will generate check_mk-style output. 


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vhl/barman_check.

