# frozen_string_literal: true

require_relative './display/display.rb'
require_relative './aggregator/aggregator.rb'
require_relative 'util.rb'

# TODO : use config, make several aggregators, use CLI options
# TODO: Add loading icon/thing while chunking data
def main
  Util.listen_for_exit
  Util.clear_term

  aggregator = Aggregator.new('Stock')
  cli = Display.new('Cli')

  sleep Cli::CLI_SPEED
  cli.display.stream(aggregator)
end

main
