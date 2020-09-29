# frozen_string_literal: true

require_relative 'util.rb'

## Keyboard shortcut registration module
module Keyboard
    # Method to create new shortcuts
    def self.add_keyboard_shortcut(key)
        @reader = TTY::Reader.new
        Util.poll(Cli::CLI_SPEED) do 
            yield if @reader.read_char == key
        end
    end

    ## SHORTCUTS ##
    # unless the logic is simple, we'll yield and require a class to implement the "callback"

    def self.listen_for_exit
        Keyboard.add_keyboard_shortcut('q') do
            exit
        end
    end

    def self.listen_for_open_feed
        Keyboard.add_keyboard_shortcut('o') do
            yield
        end
    end

    def self.listen_for_increase_speed
        Keyboard.add_keyboard_shortcut('.') do
            yield
        end
    end

    def self.listen_for_decrease_speed
        Keyboard.add_keyboard_shortcut(',') do
            yield
        end
    end

    def self.listen_for_pause
        Keyboard.add_keyboard_shortcut('p') do
            yield
        end
    end
end