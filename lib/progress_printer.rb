# A progress printer which simplifies logging the progress of loops. To use,
# create a new ProgressPrinter, and then increment inside of a loop.
#
# Example:
#
#   printer = ProgressPrinter.new(name: "Counting", total: 250)
#   printer.start
#   250.times { printer.increment }
#   printer.finish
#
# Output:
#
#   Counting:   0/250   0% calculating...
#   Counting: 100/250  40% ~1m30s
#   Counting: 200/250  80% ~30s
#   Counting: 250/250 100% 2m30s total
#
class ProgressPrinter
  DEFAULT_EVERY = 100

  class << self
    attr_accessor :silent

    def silence
      self.silent = true
    end

    def wrap(**args, &block)
      new(**args).wrap(&block)
    end
  end

  attr_reader :total, :name, :every, :out
  attr_accessor :start_time

  def initialize(total: nil, name: nil, every: DEFAULT_EVERY, out: $stdout)
    @total = total
    @name = name
    @every = every

    if self.class.silent
      @out = StringIO.new
    else
      @out = out
    end
  end

  def wrap
    start
    yield(self)
  ensure
    finish
  end

  def start
    self.start_time = Time.now
    print_progress 0
  end

  def increment(count = 1)
    n = nil
    count.times { n = enum.next }
    print_progress n if at_milestone?
  end

  def finish
    print_progress current, final: true
  end

  def percent_complete
    return unless total
    return 1.0 if current >= total
    current / total.to_f
  end

  def percent_complete_string
    return unless total
    "#{(percent_complete * 100).to_i}%"
  end

  def percent_remaining
    return unless total
    1.0 - percent_complete
  end

  def estimated_time_remaining(now = Time.now)
    return unless total
    return "calculating..." if current == 0

    "~" + self.class.format_duration(seconds_remaining(now))
  end

  def seconds_remaining(now)
    return unless total
    return if percent_remaining == 1.0
    return 0.0 if percent_remaining == 0.0

    time_passed(now) / percent_complete * (1.0 - percent_complete)
  end

  def time_passed(now = Time.now)
    return unless start_time
    now - start_time
  end

  def current
    enum.peek - 1
  end

  private

  def at_milestone?
    current % every == 0
  end

  def enum
    @enum ||= (1..Float::INFINITY).enum_for
  end

  def print_progress(n, final: false)
    buffer = StringIO.new

    buffer.print "#{name}: " if name

    if total
      buffer.print left_pad(n, total_length)
      buffer.print "/#{total} "
      buffer.print left_pad(percent_complete_string, 4)
    else
      buffer.print n
    end

    if final
      if time_passed
        buffer.print " #{self.class.format_duration(time_passed)} total"
      end
    else
      if total
        buffer.print " #{estimated_time_remaining}"
      end
    end

    out.puts buffer.string
  end

  def left_pad(string, length)
    pad_length = length - string.to_s.length
    return string if pad_length <= 0
    "#{' ' * pad_length}#{string}"
  end

  def total_length
    @total_length ||= total.to_s.length
  end

  def self.format_duration(seconds)
    seconds = seconds.to_i

    minutes = seconds / 60
    seconds = seconds % 60

    hours = minutes / 60
    minutes = minutes % 60

    days = hours / 24
    hours = hours % 24

    buffer = ""
    buffer.prepend "#{seconds.to_i}s" if seconds.nonzero?
    buffer.prepend "#{minutes.to_i}m" if minutes.nonzero?
    buffer.prepend "#{hours.to_i}h" if hours.nonzero?
    buffer.prepend "#{days.to_i}d" if days.nonzero?
    buffer = "0s" if buffer == ""
    buffer
  end
end
