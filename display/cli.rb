# frozen_string_literal: true

require 'io/console'

## Implementation of ticker for CLI displays
class Cli < Display
  attr_reader :width

  def initialize
    @width = term_width
    poll(2) { @width = term_width }
  end

  private

  def term_width
    IO.console.winsize.last
  end

  def poll(delay)
    Thread.new do
      loop do
        sleep delay
        yield
      end
    end
  end
end
