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
    parse(line) do |_time, record|
      assert_equal record, 'data' => [
        { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 24.314 },
        { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => 24.01 },
        { 'asset' => 'ETH', 'gpu' => 2, 'hash_rate' => 24.1 }
      ]
    end

    line = '1559:05:45:16:028 2100 ETH: GPU0 29.586 Mh/s, GPU1 off'
    parse(line) do |_time, record|
      assert_equal record, 'data' => [
        { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 29.586 },
        { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => -1 }
      ]
    end
  end

  test 'extracts gpu temperature' do
    line = '50259:09:27:02:820 1834 GPU 4 temp = 45, old fan speed = 0, new fan speed = 75'
    parse(line) do |_time, record|
      assert_equal record, 'data' => [
        { 'gpu' => 4, 'temperature' => 45 }
      ]
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
