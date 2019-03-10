require_relative 'optimized_2'
require 'benchmark/ips'

def reevaluate_metric
  Benchmark.ips do |bench|
    bench.report("Process 0.25 MB of data") do
      work('files/data/data_025mb.txt')
    end
  end
end

def test_correctness
  File.write('files/result.json', '')
  work('files/fixtures/test_data.txt')
  expected_result = File.read('files/fixtures/test_result.json')
  passed = expected_result == File.read('files/result.json')
  passed ? puts('PASSED') : puts('!!! TEST FAILED !!!')
end

reevaluate_metric
test_correctness
