# frozen_string_literal: true

# TODO: figure out which one of these isn't needed here, move to keyboard.rb
require 'io/console'
require 'net/ping'
require 'tty/reader'
require 'os'

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
      OS.windows? ? system('cls') : system('clear')
    end
  end

  def self.local_rsshub_online?
    Net::Ping::TCP.new('localhost', 1200, 3).ping?
  end
end
