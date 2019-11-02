# frozen_string_literal: true

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
end
