# frozen_string_literal: true

## Aggregator for files saved on disk
# Purpose: Handling the processing of aggregated data: files on disk.
class Disk < Aggregator
  attr_reader :current_file, :files, :data

  def initialize(config)
    @files = config['files']
    @current_file = @files.first
    @current_file_index = 0
    @data = load_file(@current_file)
  end

  ## Pulls the next line, if available, and
  #   returns it to the aggregator.
  # If there isn't another line, go to the next file.
  # @returns {String} - the next line in the current file
  def read
    line = '-'

    loop do
      next_file if @data.empty?
      line = @data.shift&.strip
      break unless line.empty?
    end

    line
  end

  private

  ## Load and return the lines in a given file. This assumes
  #   the file is in the disk_files directory for nuntium
  # TODO: make a file directory attr in config.json, since
  #        Disk.rb is mostly just for testing at the moment.
  # @returns {Array<String>} - Array of lines in the given file.
  def load_file(file_name)
    File.readlines("./disk_files/#{file_name}")
  end

  ## Attempt to load the next file, or reload the first file accessed
  #  TODO: an optimization would be to check the size first, and skip
  #        this logic if there's only one file...
  def next_file
    @current_file_index += 1

    if @current_file_index >= @files.length
      @current_file = @files.first
      @current_file_index = 0
    else
      @current_file = @files[@current_file_index]
    end

    @data = load_file(@current_file)
  end
end
