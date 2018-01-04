#!/usr/bin/ruby
# encoding: utf-8
#
#
require 'pp'
require 'rake'
require 'ruby-graphviz'
require 'method_source'


if RUBY_VERSION < "2.0.0"
  $stderr.puts "This won't work with Ruby < version 2.0.0\nYou are currently running #{RUBY_VERSION}"
  exit
end

require 'pp'
def parse_invocations task
  invocations = []
   task.actions.each do |action|
      text = action.source
      invocations << text.scan(/Rake::Task\["(.+)?"\]\.invoke/)
   end
   invocations.flatten
end
#/Rake::Task["(.+)?"]\.invoke
## let Rake do the parsing ...
rake = Rake::Application.new
Rake.application = rake
rake.init
rake.load_rakefile


GraphViz::options( :use => "dot" )
g = GraphViz::new( "G" , :size => "11.7,8.3", :ratio => "auto")

invokes = Hash.new {|h,k| h[k] = [] }
rake.tasks.each do |task|
  if task.class == Rake::Task
    g.add_nodes( task.to_s,
              "shape" => "cds",
              "fillcolor" => "gold2",
              "style" => "filled,bold",
              "fontname" => "monospace",
              "fontsize" => "21"
              )


  elsif task.class == Rake::FileTask
    g.add_nodes( task.to_s,
                 "shape" => "note",
                  "fillcolor" => "lightblue",
                  "style" => "filled,bold",
                  "fontname" => "monospace",
                  "fontsize" => "21"
                  )
  elsif task.class == Rake::FileCreationTask
    g.add_nodes( task.to_s,
                 "shape" => "folder",
                 "fillcolor" => "firebrick1",
                 "style" => "filled,bold",
                 "fontname" => "monospace",
                 "fontsize" => "21"
                 )
  else
    pp task
  end

  pr = task.prerequisites
  ab = pr.collect {|t| t.gsub(/^:/,"").gsub(/,$/,"")}
  ab.each { |dep| g.add_edges(task.to_s, dep.to_s,"style" => "dashed", "color"=> "darkgray", "dir"=>"none") }

  invocations = parse_invocations task
  next if invocations.empty?
  invocations.each {|inv| invokes[task.to_s] << inv }

end


invokes.each_pair do |h,k|
  k.each do |i|
    g.add_edges(h,i, "style" => "dashed", "color"=> "darkgray", "dir"=>"none")
  end
end

g.output(:pdf => "task_overview.pdf")
