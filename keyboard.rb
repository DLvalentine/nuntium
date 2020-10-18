# frozen_string_literal: true

require_relative 'util.rb'

## Keyboard shortcut registration module
# Super simple - hash that maps keybinds to a yield, so the implementing class passes a callback to it.
module Keyboard
  @key_binds = {}

  # Create a thread that listens for the keys
  def self.listener
    @reader = TTY::Reader.new
    Util.poll(Cli::CLI_SPEED) do
      key = @reader.read_char
      @key_binds[key].call if @key_binds.key?(key)
    end
  end

  # Registers the keys
  def self.add_shortcut(key)
    @key_binds[key] = -> { yield }
  end
end
