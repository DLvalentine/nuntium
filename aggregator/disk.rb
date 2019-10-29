# frozen_string_literal: true

## Aggregator for files saved on disk
# Purpose: to handling the capturing of aggregated data: files on disk.
# Assumptions: Non-binary files lol.
# Generally used for fun or, in my case, testing.
class Disk < Aggregator
  def initialize; end

  # Testing my initial thoughts on this design...and that our gems work
  def self.tester
    require 'colorize'
    puts 'hey this worked'.red
  end
end
