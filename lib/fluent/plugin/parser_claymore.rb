require 'fluent/plugin/parser'
require 'claymore/gpu_hash_rate'
require 'claymore/total_hash_rate'

module Fluent
  module Plugin
    class ClaymoreParser < Fluent::Plugin::Parser
      Fluent::Plugin.register_parser('claymore', self)

      # Extract gpu index, temperature, old and new fan speed
      #
      # Example:
      # 09:27:02:820 1834 GPU 4 temp = 45, old fan speed = 0, new fan speed = 75
      # { 'gpu' => 4, 'old_fan' => 0, 'new_fan' => 75, 'temperature' => 45 }
      GPU_TEMP = lambda do |text|
        match = text.match(/GPU (?<gpu>\d) temp = (?<temperature>\d+), old.+= (?<old_fan>\d+), new.+= (?<new_fan>\d+)/)
        match.names.zip(match.captures).map { |(k, v)| [k, v.to_i] }.push(%w[type GPU_TEMP]).to_h if match
      end

      # Extract gpu share found
      #
      # Example:
      # 11:04:02:920 234c ETH: 12/17/17-11:04:02 - SHARE FOUND - (GPU 5)
      # { 'asset' => 'ETH', 'gpu' => 5, 'share_found' => 1 }
      GPU_SHARE_FOUND = lambda do |text|
        match = text.match(/(?<asset>[A-Z]{2,}):.+SHARE FOUND.+\(GPU (?<gpu>\d+)/)
        { 'type' => 'GPU_SHARE_FOUND', 'asset' => match[:asset], 'gpu' => match[:gpu].to_i, 'count' => 1 } if match
      end

      # Extract connection lost
      #
      # Example:
      # 20:15:08:451 2338 ETH: Connection lost, retry in 20 sec..
      # { 'asset' => 'ETH', 'connection_lost' => 1 }
      CONNECTION_LOST = lambda do |text|
        match = text.match(/(?<asset>[A-Z]{2,}):.+Connection lost/)
        { 'type' => 'CONNECTION_LOST', 'asset' => match[:asset], 'count' => 1 } if match
      end

      INCORRECT_SHARE = lambda do |text|
        match = text.match(/GPU #(?<gpu>\d+) got incorrect share/)
        { 'type' => 'INCORRECT_SHARE', 'gpu' => match[:gpu].to_i, 'count' => 1 } if match
      end

      EXTRACTORS = [
        CONNECTION_LOST,
        Claymore::GPUHashRate,
        Claymore::TotalHashRate,
        GPU_SHARE_FOUND,
        GPU_TEMP,
        INCORRECT_SHARE
      ].freeze

      def parse(text)
        EXTRACTORS
          .map { |extractor| extractor.call(text) }
          .reject { |result| result.nil? || result.empty? }
          .compact
          .flatten
          .each { |result| yield time, result }
      end

      # Claymore filename include the date however,
      # Claymore log line include time without date
      def time
        parse_time(nil)
      end
    end
  end
end
