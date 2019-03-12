require_relative 'optimized_2'
require 'ruby-prof'

RubyProf.measure_mode = RubyProf::WALL_TIME

result = RubyProf.profile do
  work('files/data/data_05mb.txt', disable_gc: true)
end

# Flat
printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open("tmp/ruby_prof_flat.txt", "w+"))

# Graph
printer2 = RubyProf::GraphHtmlPrinter.new(result)
printer2.print(File.open("tmp/ruby_prof_graph.html", "w+"))

# Callstack
printer3 = RubyProf::CallStackPrinter.new(result)
printer3.print(File.open("tmp/ruby_prof_callstack.html", "w+"))

# Callgrind
printer4 = RubyProf::CallTreePrinter.new(result)
printer4.print(:path => "tmp", :profile => 'callgrind')
