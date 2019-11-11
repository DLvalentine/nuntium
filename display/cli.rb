# frozen_string_literal: true

require 'io/console'
require_relative '../util.rb'

## Implementation of ticker for CLI displays
class Cli < Display
  attr_reader :width
  CLI_SPEED = 0.10

  def initialize
    @width = term_width
    Util.poll(Cli::CLI_SPEED) { @width = term_width }
  end

  # TODO: accept multiple aggregators...
  ## Given an aggregator, continuously read from its feed
  #  and display its contents in a scrolling manner.
  #  This will continue in an infinite loop until the program
  #  is terminated via 'q' (see Util module)
  # @param {Object<Aggregator>} - The aggregator to read from
  def stream(aggregator)
    line = aggregator.feed.read

    init_indexes = lambda {
      @start = 0
      @end = @start + @width
    }

    init_indexes.call

    loop do
      print "\r#{line.slice(@start..@end)}"
      @start += 1
      @end = @start + @width
      sleep Cli::CLI_SPEED
      next unless line[@end + 1].nil?

      temp = line[@start..@end]
      line = "#{temp} * #{aggregator.feed.read}"
      init_indexes.call
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
