require_relative 'optimized_2'
require 'stackprof'

# stackprof optimized_2/tmp/stackprof.dump --text --limit 5
# stackprof optimized_2/tmp/stackprof.dump --method 'Object#work'
GC.disable
StackProf.run(mode: :wall, out: 'tmp/stackprof.dump', raw: true) do
  work('files/data/data_05mb.txt')
end
