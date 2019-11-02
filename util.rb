# frozen_string_literal: true

require 'io/console'

## Utility methods, shared between all classes
module Util
  ## Spin up a new thread to run a given block at an interval
  # @param {Number} delay - The time, in seconds to use for a delay
  # Mind the yield, this method also takes a block
  def self.poll(delay)
    Thread.new do
      loop do
        sleep delay
        yield
      end
    end
  end

  def self.listen_for_exit
    Util.poll(1) { exit if STDIN.getch == 'q' }
  end
end
