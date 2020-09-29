# frozen_string_literal: true

require 'io/console'
require 'tty/reader'

## Utility methods, shared between all classes
module Util
  ## Spin up a new thread to run a given block at an interval
  # @param {Number} delay - The time, in seconds, to use for a delay
  # Mind the yield, this method also takes a block
  def self.poll(delay)
    Thread.new do
      loop do
        sleep delay
        yield
      end
    end
  end

  # Similar to #poll, but without the looping action.
  def self.wait(delay)
    Thread.new do
      sleep delay
      yield
    end
  end

  ### TODO: this might make more sense as a Display::Cli method.
  def self.clear_term
    Thread.new do
      sleep Cli::CLI_SPEED
      system('clear') ? nil : system('cls')
    end
  end
end
