# frozen_string_literal: true

require 'io/console'
require_relative '../util.rb'
require_relative '../keyboard.rb'

## Implementation of ticker for CLI displays
class Cli < Display
  attr_reader :width
  CLI_SPEED = 0.10
  PAUSE_TIME_SECS = 5

  def initialize
    @width = term_width
    @cli_speed_offset = 0

    Keyboard.add_shortcut(',') { @cli_speed_offset += 0.01 }
    Keyboard.add_shortcut('.') { (Cli::CLI_SPEED + @cli_speed_offset - 0.01).positive? ? @cli_speed_offset -= 0.01 : nil }
    Keyboard.add_shortcut('/') { @cli_speed_offset = 0 }
    Keyboard.add_shortcut('p') { 
      offset_before_pause = @cli_speed_offset
      @cli_speed_offset = Cli::PAUSE_TIME_SECS
      sleep 0.1
      @cli_speed_offset = offset_before_pause # after the short pause, return to the old speed
    }
    Util.poll(Cli::CLI_SPEED) { @width = term_width }
  end

  ## Given an array of aggregators, continuously read from its feed
  #  and display its contents in a scrolling manner.
  #  This will continue in an infinite loop until the program
  #  is terminated via 'q' (see Util module)
  # @param {Array<Object<Aggregator>>} - The aggregators to read from
  def stream(aggregators)
    current = 0

    line = "#{' ' * @width}#{aggregators[current].feed.read}"

    next_agg = lambda {
      if current < aggregators.length - 1
        current += 1
      else
        current = 0
      end
    }

    init_indexes = lambda {
      @start = 0
      @end = @start + @width
    }

    init_indexes.call
    next_agg.call

    loop do
      print "\r#{line.slice(@start..@end)}"
      @start += 1
      @end = @start + @width
      sleep Cli::CLI_SPEED + @cli_speed_offset
      next unless line[@end + 1].nil?

      temp = line[@start..@end]
      line = "#{temp} * #{aggregators[current].feed.read}"
      init_indexes.call
      next_agg.call
    end
  end

  private

  ## Returns the terminal width in columns
  # @return {Number} - the width
  def term_width
    new_width = IO.console.winsize.last - 1
    Util.clear_term if @width && new_width < @width
    new_width
  end
end
