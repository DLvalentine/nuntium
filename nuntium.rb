# frozen_string_literal: true

require_relative './display/display.rb'
require_relative './aggregator/aggregator.rb'
require_relative 'util.rb'

# TODO : use config, make several aggregators, use CLI options
# TODO: Add loading icon/thing while chunking data
def main
  Util.listen_for_exit
  Util.clear_term

  ## TODO: check configs, create for that
  ## TODO: loading text based on ^ to load for each
  ## TODO: make sure this thread gets killed...
  Util.poll(Cli::CLI_SPEED) { print "\rLoading data..." unless caches_valid? }

  stock = Aggregator.new('Stock')
  rss   = Aggregator.new('Rss')

  cli = Display.new('Cli')

  sleep Cli::CLI_SPEED
  cli.display.stream([rss, stock, stock, stock])
end

# TODO: invalidate cache frfr when they are old or mismatched...
def caches_valid?
  File.exist?(Rss::CACHE_FILENAME) && File.exist?(Stock::CACHE_FILENAME)
end

main
