# frozen_string_literal: true

require 'io/console'
require_relative '../util.rb'

## Implementation of ticker for CLI displays
class Cli < Display
  attr_reader :width
  CLI_SPEED = 0.10

  ### ISSUES (FIXME): 
  # Resize: Going larger is fine, going smaller creates newlines
  # Newlines: newlines are returned when typing.

  def initialize
    @width = term_width
    Util.poll(Cli::CLI_SPEED) { @width = term_width }
  end

  # TODO: accept multiple aggregators
  def stream(aggregator)
    ## Consider: This actually works just fine for disk files.
    #            I think "chunking" would only be needed for
    #            RSS feeds...
    line = aggregator.feed.read
    @start = 0
    @end = @start + @width
    loop do
      printf("\r#{line.slice(@start..@end)}")
      @start += 1
      @end = @start + @width
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
