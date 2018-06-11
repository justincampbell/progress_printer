# ProgressPrinter [![Gem Version](https://badge.fury.io/rb/progress_printer.svg)](https://badge.fury.io/rb/progress_printer) [![Build Status](https://travis-ci.org/justincampbell/progress_printer.svg?branch=master)](https://travis-ci.org/justincampbell/progress_printer)

> Logs the progress of an operation, with estimated completion time.

## Installation

When using [Bundler](https://bundler.io), add this to your project's `Gemfile`:

```ruby
gem 'progress_printer'
```

Otherwise, install it with the `gem` command:


```shell
$ gem install progress_printer
```

### Already in a console?

Progress Printer is in a single with no dependencies, so you're able to copy/paste the entire file into an `irb` session, and then immediately use `ProgressPrinter.new` (see below). The raw source to copy is available here:

[https://raw.githubusercontent.com/justincampbell/progress_printer/master/lib/progress_printer.rb](https://raw.githubusercontent.com/justincampbell/progress_printer/master/lib/progress_printer.rb)

## Usage

### Basic Usage

A `ProgressPrinter` must be created, started, and finished. Use `#increment` within your operation to increment the progress.

```rb
require 'progress_printer'

printer = ProgressPrinter.new(name: "Counting", total: 250)
printer.start
250.times { sleep 0.05; printer.increment }
printer.finish
```

Output:

```
Counting:   0/250   0% calculating...
Counting: 100/250  40% ~8s
Counting: 200/250  80% ~2s
Counting: 250/250 100% 14s total
```

You can also achieve the same results by using `.wrap` or `#wrap`:

```rb
ProgressPrinter.wrap(name: "Counting", total: 250) do |progress|
  250.times { sleep 0.05; progress.increment }
end
```

```rb
printer = ProgressPrinter.new(name: "Counting", total: 250)
printer.wrap do |progress|
  250.times { sleep 0.05; progress.increment }
end
```

### Arguments

* `total` - The total number of iterations expected. If this is omitted, estimated completion time will not be shown.
* `name` - A string to display next to each printed line. This helps identify the current operation, or the specific progress printer if using multiple.
* `every` (Default: `100`) - How many iterations should pass in between printing a line.
* `out` (Default: `$stdout`) - An object responding to `#puts` for printing the progress to.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/justincampbell/progress_printer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
