# frozen_string_literal: true

require 'io/console'
require_relative '../util.rb'

## Implementation of ticker for CLI displays
class Cli < Display
  attr_reader :width

  def initialize
    @width = term_width
    Util.poll(2) { @width = term_width }
  end

  # TODO: accept multiple aggregators
  def chunk(aggregator)
    chunks = []
    
    3.times do 
      chunks.push(aggregator.feed.read)
    end

    chunks
  end

  # TODO: accept multiple aggregators
  def stream(aggregator)
    stream = chunk(aggregator)
    loop do
      if stream.size > 0 
        puts "\r#{stream.shift}"
        sleep 2
      else
        stream = chunk(aggregator)
      end 
    end
  end

  private

  ## Returns the terminal width in columns
  # @return {Number} - the width
  def term_width
    IO.console.winsize.last
  end
end
