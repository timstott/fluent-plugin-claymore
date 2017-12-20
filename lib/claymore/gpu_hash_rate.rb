require 'claymore/asset_symbol'

module Claymore
  # Extracts asset, gpu index and gpu hash rate
  # Sets hash rate to -1 when gpu is off
  #
  # Example input:
  # 05:45:16:028 2100 ETH: GPU0 29.586 Mh/s, GPU1 off
  #
  # Example output:
  # [
  #   { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 29.586, 'type' => 'GPU_HASH_RATE' },
  #   { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => -1.0, 'type' => 'GPU_HASH_RATE' }
  # ]
  class GPUHashRate
    include AssetSymbol

    RATES_REGEXP = %r{GPU(?<index>\d+) (?<rate>\d+(?:\.\d+)? Mh\/s|off)}
    LINE_REGEXP = Regexp.new("#{ASSET_REGEXP.source} #{RATES_REGEXP.source}")

    def self.call(line)
      new(line).call
    end

    attr_reader :line

    def initialize(line)
      @line = line
    end

    # rubocop:disable Metrics/MethodLength
    def call
      (match = LINE_REGEXP.match(line)) || return

      raw_rates.each_with_object([]) do |(raw_index, raw_rate), acc|
        hash_rate = raw_rate == 'off' ? -1.0 : raw_rate.to_f.round(3)
        index = raw_index.to_i

        acc << {
          'type' => 'GPU_HASH_RATE',
          'asset' => match[:asset],
          'gpu' => index,
          'hash_rate' => hash_rate
        }
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def raw_rates
      line.scan(RATES_REGEXP)
    end
  end
end
