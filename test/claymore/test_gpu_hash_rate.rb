require 'helper'
require 'claymore/gpu_hash_rate.rb'

class GPUHashRateTest < Test::Unit::TestCase
  test 'return nil when no match' do
    assert_nil service('ETH: GPU0')
    assert_nil service('GPU0 24.1 Mh/s')
    assert_nil service('SC - Total Speed: 292.684 Mh/s')
  end

  test 'extracts individual GPU hash rates when available' do
    text = 'ETH: GPU0 24.314 Mh/s, GPU1 24.01 Mh/s, GPU20 24.1 Mh/s'
    assert_equal service(text), [
      { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 24.314, 'type' => 'GPU_HASH_RATE' },
      { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => 24.01, 'type' => 'GPU_HASH_RATE' },
      { 'asset' => 'ETH', 'gpu' => 20, 'hash_rate' => 24.1, 'type' => 'GPU_HASH_RATE' }
    ]
  end

  test 'extracts asset name' do
    text = 'SC: GPU0 292.862 Mh/s'
    assert_equal service(text), [
      { 'asset' => 'SC', 'gpu' => 0, 'hash_rate' => 292.862, 'type' => 'GPU_HASH_RATE' }
    ]
  end

  test 'assigns -1 hash rate value when GPU is off' do
    text = 'ETH: GPU0 29 Mh/s, GPU1 off'
    assert_equal service(text), [
      { 'asset' => 'ETH', 'gpu' => 0, 'hash_rate' => 29, 'type' => 'GPU_HASH_RATE' },
      { 'asset' => 'ETH', 'gpu' => 1, 'hash_rate' => -1.0, 'type' => 'GPU_HASH_RATE' }
    ]

    text = 'LBC: GPU0 off'
    assert_equal service(text), [
      { 'asset' => 'LBC', 'gpu' => 0, 'hash_rate' => -1.0, 'type' => 'GPU_HASH_RATE' }
    ]
  end

  def service(text)
    Claymore::GPUHashRate.call(text)
  end
end
