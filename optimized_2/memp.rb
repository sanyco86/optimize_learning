require_relative 'optimized_2'
require 'memory_profiler'

report = MemoryProfiler.report do
  work('files/data/data_05mb.txt')
end
report.pretty_print(scale_bytes: true)
