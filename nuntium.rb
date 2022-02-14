# frozen_string_literal: true

require_relative './display/display'
require_relative './aggregator/aggregator'
require_relative 'util'
require_relative 'keyboard'

# TODO: Add improved loading icon/thing while chunking data
def main
  # Clear term of old data
  Util.clear_term

  # TODO: make sure this thread gets killed...after you add in the frfr invalidation...
  @chunk = 'RSS data'
  @loading_thread = Util.poll(Cli::CLI_SPEED) { print "\rLoading #{@chunk}..." unless caches_valid? }
  Util.poll(30) { Util.clear_term }

  # Set up cli display
  cli = Display.new('Cli')
  sleep Cli::CLI_SPEED
  Util.clear_term

  # Setup config, add exit hook, start listening for keys.
  # NOTE: read_config needs to run before Keyboard.listener, in case any Aggregators register shortcuts
  @enable_ifeeds = false
  config = read_config
  # TODO: Mac compat - basically a ruby script I guess... or fallback scripts
  Keyboard.add_shortcut('q') do
    exit!
  end

  Keyboard.add_shortcut('c') do
    Util.clear_term
  end

  Keyboard.enable_listener

  # start streaming data
  @loading_thread.kill if caches_valid?
  Util.clear_term
  cli.display.stream(config) if caches_valid?
end

# TODO: invalidate cache frfr when they are old or mismatched...this is happening at the aggregator level right now
# TODO: this might be better off in util?
def caches_valid?
  rss_feeds_exist = File.exist?(Rss::CACHE_FILENAME)
  stock_feeds_exists = File.exist?(Stock::CACHE_FILENAME)

  @chunk = rss_feeds_exist ? 'Stock Symbol data' : 'RSS data'

  rss_feeds_exist && stock_feeds_exists
end

# reads the config.json file at the root, and constructs the aggregator array
# @returns {Array<Aggregator>} to be used in display
# TODO: this might be better off in util?
def read_config
  stream_format = JSON.parse(File.read('./config.json'))['displays']['stream_format']
  @enable_ifeeds = !JSON.parse(File.read('./config.json'))['aggregators']['rss']['i_feeds'].empty?

  # If ifeeds are enabled, use them
  if @enable_ifeeds
    # TODO implement
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
