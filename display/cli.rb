# frozen_string_literal: true

require 'io/console'
require_relative '../util.rb'

## Implementation of ticker for CLI displays
class Cli < Display
  attr_reader :width
  CLI_SPEED = 0.10

  def initialize
    @width = term_width
    Util.poll(2) { @width = term_width }
  end

  # TODO: accept multiple aggregators
  def stream(aggregator)
    line = aggregator.feed.read ### HACK: this actually works a lot better than chunking. Might just need chunking for RSS feeds
    @start = 0
    @end = @width
    loop do
      printf("\r#{line.slice(@start..@end)}")
      @start += 1
      @end += 1 ### FIXME: doing it this way prevents the width adjust from working
      sleep Cli::CLI_SPEED
      line += " * #{aggregator.feed.read}" if line[@end + 1].nil?
    end
  end

  private

  ## Returns the terminal width in columns
  # @return {Number} - the width
  def term_width
    IO.console.winsize.last - 1
  end
end
