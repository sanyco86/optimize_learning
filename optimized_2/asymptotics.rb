require_relative 'optimized_2'
require 'benchmark/ips'

Benchmark.ips do |bench|
  bench.warmup = 0
  bench.report("Process 0.0625Mb") { work('files/data/data_00625mb.txt') }
  bench.report("Process 0.125Mb")  { work('files/data/data_0125mb.txt') }
  bench.report("Process 0.25Mb")   { work('files/data/data_025mb.txt') }
  bench.report("Process 0.5Mb")    { work('files/data/data_05mb.txt') }
  bench.report("Process 1Mb")      { work('files/data/data_1mb.txt') }
  bench.report("Process 2Mb")      { work('files/data/data_2mb.txt') }

  bench.compare!
end
