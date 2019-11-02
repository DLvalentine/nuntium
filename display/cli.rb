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

  private

  ## Returns the terminal width in columns
  # @return {Number} - the width
  def term_width
    IO.console.winsize.last
  end
end
