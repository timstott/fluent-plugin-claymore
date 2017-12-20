require 'fluent/plugin/parser'

module Fluent
  module Plugin
    class ClaymoreParser < Fluent::Plugin::Parser
      Fluent::Plugin.register_parser('claymore', self)

      # Extract asset, gpu index and hash rate
      # Sets hash rate to -1 when gpu is off
      #
      # Example:
      # 15:05:45:16:028 2100 ETH: GPU0 29.586 Mh/s, GPU1 off
      # [
      #   { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 29.586 },
      #   { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => -1 }
      # ]
      GPU_HASH_RATE = lambda do |text|
        return unless text =~ %r{[A-Z]{3,}: GPU\d.+Mh\/s}

        asset = text.match(/(?<asset>[A-Z]{3,}): GPU/)[:asset]
        text.scan(/(\d+\.\d+|off)/).flatten.each.with_index.each_with_object([]) do |(raw_rate, index), acc|
          hash_rate = raw_rate == 'off' ? -1 : raw_rate.to_f.round(3)

          acc << { 'asset' => asset, 'gpu' => index, 'hash_rate' => hash_rate }
        end
      end

      # Extract gpu index and temperature
      #
      # Example:
      # 21:09:27:02:820 1834 GPU 4 temp = 45, old fan speed = 0, new fan speed = 75
      # [
      #   { 'gpu' => 4, 'temperature' => 45 }
      # ]
      GPU_TEMP = lambda do |text|
        match = text.match(/GPU (?<gpu>\d) temp = (?<temperature>\d+)/)
        if match
          result = match.names.zip(match.captures).map { |(k, v)| [k, v.to_i] }.to_h
          [result]
        end
      end

      # NOTE: extractors must always envelop data in an array
      EXTRACTORS = [GPU_HASH_RATE, GPU_TEMP].freeze

      def parse(text)
        data = EXTRACTORS
               .map { |e| e.call(text) }
               .reject { |r| r.nil? || r.empty? }
               .compact
               .first

        result = data ? { 'data' => data } : nil

        yield time, result
      end

      # Claymore filename include the date however,
      # Claymore log line include time without date
      def time
        Time.now
      end
    end
  end
end
