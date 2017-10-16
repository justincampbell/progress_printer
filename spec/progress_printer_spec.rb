require 'spec_helper'
require 'progress_printer'

RSpec.describe ProgressPrinter do
  subject(:printer) {
    described_class.new(
      name: name,
      every: every,
      total: total,
      out: output
    )
  }

  let(:output) { StringIO.new }
  let(:total) { nil }
  let(:name) { nil }
  let(:every) { described_class::DEFAULT_EVERY }

  before do
    allow_any_instance_of(ProgressPrinter)
      .to receive(:testing?)
      .and_return(false)
  end

  context "example with all options" do
    let(:total) { 250 }
    let(:name) { "Counting" }
    let(:every) { 100 }

    it "prints the progress of a loop" do
      printer.start
      250.times { printer.increment }
      printer.finish
      expect(output.string).to eq(
        <<-OUTPUT.gsub(/^\s*/, '')
          Counting:   0/250   0% calculating...
          Counting: 100/250  40% ~0s
          Counting: 200/250  80% ~0s
          Counting: 250/250 100% ~0s
        OUTPUT
      )
    end
  end

  describe ".format_duration" do
    {
      0 => "0s",
      1 => "1s",
      60 => "1m",
      90 => "1m30s",
      3600 => "1h",
      9030 => "2h30m30s",
      604800 => "7d",
      1234567890 => "14288d23h31m30s"
    }.each do |seconds, expected|
      it "converts #{seconds} seconds to #{expected}" do
        expect(described_class.format_duration(seconds)).to eq(expected)
      end
    end
  end

  describe ".wrap" do
    it "creates a new instance with all args and wraps the given block" do
      described_class.wrap name: "Count", every: 1, total: 1, out: output do |progress|
        progress.increment
      end

      expect(output.string).to eq(
        <<-OUTPUT.gsub(/^\s*/, '')
          Count: 0/1   0% calculating...
          Count: 1/1 100% ~0s
          Count: 1/1 100% ~0s
        OUTPUT
      )
    end
  end

  describe "#wrap" do
    it "starts and finishes around a given block" do
      expect(printer).to receive(:start).and_call_original
      expect(printer).to receive(:finish).and_call_original

      printer.wrap do |printer|
        printer.increment
      end

      expect(output.string).to eq("0\n1\n")
    end

    it "returns the value of the block" do
      result = printer.wrap { :abc }

      expect(result).to eq(:abc)
    end
  end

  describe "#start" do
    it "prints 0" do
      printer.start
      expect(output.string).to eq("0\n")
    end

    context "with a name" do
      let(:name) { "Hard Work" }

      it "prefixes the name" do
        printer.start
        expect(output.string).to eq("Hard Work: 0\n")
      end
    end

    context "with a total" do
      let(:total) { 5 }

      it "prints 0 out of total" do
        printer.start
        expect(output.string).to eq("0/5   0% calculating...\n")
      end

      context "with a longer total" do
        let(:total) { 12345 }

        it "left-pads the progress" do
          printer.start
          expect(output.string).to eq("    0/12345   0% calculating...\n")
        end
      end
    end
  end

  describe "#increment" do
    it "does not print before reaching the every number" do
      99.times { printer.increment }
      expect(output.string).to eq("")
    end

    it "prints when reaching the every number" do
      100.times { printer.increment }
      expect(output.string).to eq("100\n")
    end

    context "with a count" do
      it "increments by that count" do
        printer.increment(123)
        expect(printer.current).to eq(123)
      end
    end
  end

  describe "#finish" do
    it "prints the current number" do
      123.times { printer.increment }
      output.reopen
      printer.finish
      expect(output.string).to eq("123\n")
    end

    context "with a total" do
      let(:total) { 123 }

      it "prints the total" do
        printer.finish
        expect(output.string).to eq("123/123   0% calculating...\n")
      end
    end

    context "when the total was already printed" do
      before do
        100.times { printer.increment }
        expect(output.string).to eq("100\n")
        output.reopen
      end

      it "does not print the total again" do
        printer.finish
        expect(output.string).to eq("")
      end
    end
  end

  describe "#percent_complete" do
    subject(:percent_complete) { printer.percent_complete }

    it { is_expected.to eq(nil) }

    context "with a total" do
      let(:total) { 20 }

      it { is_expected.to eq(0.0) }

      context "when a quarter done" do
        before { (total / 4).times { printer.increment } }

        it { is_expected.to eq(0.25) }
      end

      context "when over incremented" do
        before { (total + 1).times { printer.increment } }

        it { is_expected.to eq(1.0) }
      end
    end

    context "with a zero total" do
      let(:total) { 0 }

      it { is_expected.to eq(1.0) }
    end
  end

  describe "#percent_complete_string" do
    subject(:percent_complete_string) { printer.percent_complete_string }

    it { is_expected.to eq(nil) }

    context "with a total" do
      let(:total) { 20 }

      it { is_expected.to eq("0%") }

      context "when a quarter done" do
        before { (total / 4).times { printer.increment } }

        it { is_expected.to eq("25%") }
      end

      context "when over incremented" do
        before { (total + 1).times { printer.increment } }

        it { is_expected.to eq("100%") }
      end
    end

    context "with a zero total" do
      let(:total) { 0 }

      it { is_expected.to eq("100%") }
    end
  end

  describe "#percent_remaining" do
    subject(:percent_remaining) { printer.percent_remaining }

    it { is_expected.to eq(nil) }

    context "with a total" do
      let(:total) { 20 }

      it { is_expected.to eq(1.0) }

      context "when a quarter done" do
        before { (total / 4).times { printer.increment } }

        it { is_expected.to eq(0.75) }
      end

      context "when over incremented" do
        before { (total + 1).times { printer.increment } }

        it { is_expected.to eq(0.0) }
      end
    end

    context "with a zero total" do
      let(:total) { 0 }

      it { is_expected.to eq(0.0) }
    end
  end

  describe "#estimated_time_remaining" do
    subject(:estimated_time_remaining) {
      printer.estimated_time_remaining(current_time)
    }

    let(:start_time) { Time.new(2016, 1, 2, 3, 4, 5, 6) }
    let(:current_time) { start_time }

    before { printer.start_time = start_time }

    it { is_expected.to eq(nil) }

    context "with a total" do
      let(:total) { 20 }

      it { is_expected.to eq("calculating...") }

      context "when 10 percent done" do
        before { (total / 10).times { printer.increment } }

        it { is_expected.to eq("~0s") }

        context "when 1 second has passed" do
          let(:current_time) { start_time + 1 }

          it { is_expected.to eq("~9s") }
        end

        context "when 10 seconds have passed" do
          let(:current_time) { start_time + 10 }

          it { is_expected.to eq("~1m30s") }
        end
      end

      context "when 50 percent done" do
        before { (total / 2).times { printer.increment } }

        it { is_expected.to eq("~0s") }

        context "when 1 second has passed" do
          let(:current_time) { start_time + 1 }

          it { is_expected.to eq("~1s") }
        end

        context "when 10 seconds have passed" do
          let(:current_time) { start_time + 10 }

          it { is_expected.to eq("~10s") }
        end
      end

      context "when done" do
        before { total.times { printer.increment } }

        it { is_expected.to eq("~0s") }

        context "when 1 second has passed" do
          let(:current_time) { start_time + 1 }

          it { is_expected.to eq("~0s") }
        end

        context "when 10 seconds have passed" do
          let(:current_time) { start_time + 10 }

          it { is_expected.to eq("~0s") }
        end
      end
    end
  end

  describe "#seconds_remaining" do
    subject(:seconds_remaining) { printer.seconds_remaining(current_time) }

    let(:start_time) { Time.new(2016, 1, 2, 3, 4, 5, 6) }
    let(:current_time) { start_time }

    before { printer.start_time = start_time }

    it { is_expected.to eq(nil) }

    context "with a total" do
      let(:total) { 20 }

      it { is_expected.to eq(nil) }

      context "when 10 percent done" do
        before { (total / 10).times { printer.increment } }

        it { is_expected.to eq(0.0) }

        context "when 1 second has passed" do
          let(:current_time) { start_time + 1 }

          it { is_expected.to eq(9.0) }
        end

        context "when 10 seconds have passed" do
          let(:current_time) { start_time + 10 }

          it { is_expected.to eq(90.0) }
        end
      end

      context "when 50 percent done" do
        before { (total / 2).times { printer.increment } }

        it { is_expected.to eq(0.0) }

        context "when 1 second has passed" do
          let(:current_time) { start_time + 1 }
          it { is_expected.to eq(1.0) }
        end

        context "when 10 seconds have passed" do
          let(:current_time) { start_time + 10 }

          it { is_expected.to eq(10.0) }
        end
      end

      context "when done" do
        before { total.times { printer.increment } }

        it { is_expected.to eq(0.0) }

        context "when 1 second has passed" do
          let(:current_time) { start_time + 1 }
          it { is_expected.to eq(0.0) }
        end

        context "when 10 seconds have passed" do
          let(:current_time) { start_time + 10 }

          it { is_expected.to eq(0.0) }
        end
      end

      context "when over incremented" do
        before { (total + 1).times { printer.increment } }

        it { is_expected.to eq(0.0) }

        context "when 1 second has passed" do
          let(:current_time) { start_time + 1 }
          it { is_expected.to eq(0.0) }
        end

        context "when 10 seconds have passed" do
          let(:current_time) { start_time + 10 }

          it { is_expected.to eq(0.0) }
        end
      end
    end
  end
end
