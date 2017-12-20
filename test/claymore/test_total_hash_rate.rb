require 'helper'
require 'claymore/total_hash_rate.rb'

class TotalHashRateTest < Test::Unit::TestCase
  test 'return nil when no match' do
    assert_nil service('ETH: job is the same')
    assert_nil service('ETH: checking pool connection...')
    assert_nil service('ETH: GPU0 29 Mh/s, GPU1 off')
  end

  test 'extracts asset name and total hash rate' do
    line = 'ETH - Total Speed: 90.118 Mh/s, Total Shares: 237, Rejected: 0, Time: 06:50'
    assert_equal ({
      'asset' => 'ETH',
      'hash_rate' => 90.118,
      'type' => 'TOTAL_HASH_RATE'
    }), service(line)
  end

  def service(line)
    Claymore::TotalHashRate.call(line)
  end
end
