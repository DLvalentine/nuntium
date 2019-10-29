# frozen_string_literal: true

## Aggregator for files saved on disk
# Purpose: to handling the capturing of aggregated data: files on disk.
# Assumptions: Non-binary files lol.
# Generally used for fun or, in my case, testing.
class Disk < Aggregator
  attr_reader :current_file, :files
  
  def initialize(config) 
    @files = config['files']
    @current_file = @files.first
  end
end
