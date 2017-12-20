require 'claymore/asset_symbol'

module Claymore
  # Extracts total hash rate with asset symbol
  #
  # Example input:
  # 05:45:16:028 2100 ETH - Total Speed: 90.118 Mh/s, Total Shares: 237, Rejected: 0, Time: 06:50
  #
  # Example output:
  # { 'asset' => 'ETH', 'hash_rate' => 90.118, 'type' => 'TOTAL_HASH_RATE' }
  class TotalHashRate
    include AssetSymbol

    TOTAL_RATE_REGEXP = %r{Total Speed: (?<rate>\d+\.\d+ Mh\/s)}
    LINE_REGEXP = Regexp.new("#{ASSET_REGEXP.source} #{TOTAL_RATE_REGEXP.source}")

    def self.call(line)
      new(line).call
    end

    attr_reader :line

    def initialize(line)
      @line = line
    end

    def call
      (match = LINE_REGEXP.match(line)) || return

      {
        'asset' => match[:asset],
        'hash_rate' => match[:rate].to_f.round(3),
        'type' => 'TOTAL_HASH_RATE'
      }
    end
  end
end
