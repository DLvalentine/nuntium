# frozen_string_literal: true

require_relative './display/display.rb'
require_relative './aggregator/aggregator.rb'
require_relative 'util.rb'
require_relative 'keyboard.rb'

# TODO: Add improved loading icon/thing while chunking data
def main
  # Clear term of old data
  Util.clear_term

  # TODO: make sure this thread gets killed...after you add in the frfr invalidation... include better loading text info?
  Util.poll(Cli::CLI_SPEED) { print "\rLoading data..." unless caches_valid? }
  Util.poll(30) { Util.clear_term }

  # Set up cli display
  cli = Display.new('Cli')
  sleep Cli::CLI_SPEED
  Util.clear_term

  # Setup config, add exit hook, start listening for keys.
  # NOTE: read_config needs to run before Keyboard.listener, in case any Aggregators register shortcuts
  @enable_rsshub = false
  config = read_config
  # TODO: Mac compat - basically a ruby script I guess... or fallback scripts
  Keyboard.add_shortcut('q') do
    if @enable_rsshub
      system('start /min rsshub_exit.bat')
    end
    exit!
  end

  Keyboard.add_shortcut('c') do 
    Util.clear_term
  end
  
  Keyboard.listener

  # start streaming data
  Util.clear_term
  cli.display.stream(config)
end

# TODO: invalidate cache frfr when they are old or mismatched...this is happening at the aggregator level right now
# TODO: this might be better off in util?
def caches_valid?
  File.exist?(Rss::CACHE_FILENAME) && File.exist?(Stock::CACHE_FILENAME)
end

# reads the config.json file at the root, and constructs the aggregator array
# @returns {Array<Aggregator>} to be used in display
# TODO: this might be better off in util?
def read_config
  stream_format = JSON.parse(File.read('./config.json'))['displays']['stream_format']
  @enable_rsshub = !JSON.parse(File.read('./config.json'))['aggregators']['rss']['i_feeds'].empty?

  # If rsshub is enabled (i_feeds has at least one entry), spin up the service locally
  if @enable_rsshub
    # TODO: make sure this thread gets killed... include better loading text info?
    Util.poll(Cli::CLI_SPEED) { print "\rStarting RSSHub..." unless Util.local_rsshub_online? }
    Thread.new do
      # TODO: - Mac compatibility...
      system('start "RSSHUB" /min rsshub.bat') unless Util.local_rsshub_online?
    end
    sleep 1 until Util.local_rsshub_online?
    Util.clear_term
  end

  disk  = stream_format.include?('disk') ? Aggregator.new('disk') : nil
  rss   = stream_format.include?('rss') ? Aggregator.new('rss') : nil
  stock = stream_format.include?('stock') ? Aggregator.new('stock') : nil

  stream_format.map do |frmt|
    case frmt
    when 'disk'
      disk
    when 'rss'
      rss
    when 'stock'
      stock
    end
  end
end

## Program execution
main
