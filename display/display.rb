# frozen_string_literal: true

## Parent class for the display/ticking, as it were
class Display
  require_relative 'cli.rb'

  attr_reader :display

  def initialize(type)
    @type = type
    @display = Object.const_get(type).new
  end
end
