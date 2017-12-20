require 'helper'
require 'fluent/plugin/parser_claymore.rb'

class ClaymoreParserTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test 'uses current Time instead of file/line time' do
    t1 = '2017-12-20T07:30:05.123+00:00'
    Timecop.freeze(t1) do
      parse('') do |time, _record|
        assert_equal time, Time.parse(t1)
      end
    end
  end

  test 'returns nothing when no match' do
    parse('blahblah') do |_time, record|
      assert_nil record
    end
  end

  test 'extracts gpu hash rates' do
    line = '17:22:59:067 25e8 ETH: GPU0 24.314 Mh/s, GPU1 24.01 Mh/s, GPU2 24.1 Mh/s'
    records = []
    parse(line) { |_time, record| records.push record }
    assert_equal records, [
      { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 24.314, 'type' => 'GPU_HASH_RATE' },
      { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => 24.01, 'type' => 'GPU_HASH_RATE' },
      { 'asset' => 'ETH', 'gpu' => 2, 'hash_rate' => 24.1, 'type' => 'GPU_HASH_RATE' }
    ]
  end

  test 'extracts gpu hash rates with off gpus' do
    line = '1559:05:45:16:028 2100 ETH: GPU0 29.586 Mh/s, GPU1 off'
    records = []
    parse(line) { |_time, record| records.push record }
    assert_equal records, [
      { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 29.586, 'type' => 'GPU_HASH_RATE' },
      { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => -1, 'type' => 'GPU_HASH_RATE' }
    ]
  end

  test 'extracts gpu temperature, old and new fan speed' do
    line = '09:27:02:820 1834 GPU 4 temp = 45, old fan speed = 0, new fan speed = 75'
    parse(line) do |_time, record|
      assert_equal record, 'gpu' => 4, 'old_fan' => 0, 'new_fan' => 75, 'temperature' => 45, 'type' => 'GPU_TEMP'
    end
  end

  test 'extracts gpu share found' do
    line = '11:04:02:920 234c ETH: 12/17/17-11:04:02 - SHARE FOUND - (GPU 5)'
    parse(line) do |_time, record|
      assert_equal record, 'asset' => 'ETH', 'gpu' => 5, 'count' => 1, 'type' => 'GPU_SHARE_FOUND'
    end
  end

  test 'extracts connection lost' do
    line = '20:15:08:451 2338 ETH: Connection lost, retry in 20 sec...'
    parse(line) do |_time, record|
      assert_equal record, 'asset' => 'ETH', 'count' => 1, 'type' => 'CONNECTION_LOST'
    end
  end

  test 'extracts incorrect share' do
    line = '05:07:23:959 acc GPU #3 got incorrect share. If you see this warning often, make sure you did not overclock it too much!'
    parse(line) do |_time, record|
      assert_equal record, 'gpu' => 3, 'count' => 1, 'type' => 'INCORRECT_SHARE'
    end
  end

  private

  def parse(txt, &block)
    create_driver({}).instance.parse(txt, &block)
  end

  def create_driver(conf)
    Fluent::Test::Driver::Parser.new(Fluent::Plugin::ClaymoreParser).configure(conf)
  end
end
