# frozen_string_literal: true

## Parent class for the display/ticking, as it were
# TODO / NOTE: This was an attempt many years ago by me to play around with inheritence/polymorphism in Ruby... it did not go as planned.
#               as such, this... is kinda just like a factory now, for pumping out classes. Kinda metaprogramming except not.
#               It works, so I'm probably not going to change it, but it is over-engineered for what it does. Maybe I will change it idk.
class Display
  require_relative 'cli.rb'

  attr_reader :display

  def initialize(type)
    @type = type
    begin
      @display = Object.const_get(type).new
    rescue NameError
      raise ArgumentError, "Display class \"#{@type}\" does not exist."
    end
  end

  ## TODO: Only here to serve as an implementation reminder. Remove for prod.
  # rubocop:disable all
  def method_missing(method_called)
    raise StandardError, 
      "Method \"#{method_called}\" does not exist for Display class: #{@type}"
  end
  # rubocop:enable all
end
