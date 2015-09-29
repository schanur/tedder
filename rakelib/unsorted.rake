# -*- coding: utf-8 -*-

require 'rake'
#require 'rake/clean'

load('rakelib/cmd_params.rake')
load('rakelib/relative_work_items.rake')

$opt = Hash.new

parse_cmd_params($opt)

# puts RUBY_VERSION
# exit 1

# task      :default         => [:help]

desc 'Build all software components'
task      :build,           [:opt] do |t, args|
  args.with_defaults(:opt => default_options()) if args[:opt].nil?
  Rake::Task[:c_obj                ].invoke(args[:opt])
  Rake::Task[:link                 ].invoke(args[:opt])
end



desc 'Link binary, shared library and static library'
# multitask :link            => [:link_binary, :link_static_lib, :link_shared_lib]
task      :link,           [:opt] do |t, args|
  args.with_defaults(:opt => default_options()) if args[:opt].nil?
  parallel_invoke(task_list_with_options([:link_binary, :link_static_lib, :link_shared_lib], args[:opt]))
end

desc 'Compile all C modules'
# multitask :c_obj           => c_dep_job
task      :c_obj,           [:opt] do |t, args|
  args.with_defaults(:opt => default_options()) if args[:opt].nil?
  parallel_invoke(task_list_with_options(c_dep_job_file_list().map { |file| File.join(args[:opt]['build_dir'], file) }, args[:opt]))
end

desc 'Link binaries'
task      :link_binary,           [:opt] do |t, args|
  Rake::Task[File.join(args[:opt]['build_dir'], $binary)    ].invoke(args[:opt])
end

desc 'Link static library'
task      :link_static_lib,       [:opt] do |t, args|
  Rake::Task[File.join(args[:opt]['build_dir'], $static_lib)].invoke(c_obj_file_list().map { |f| File.join(args[:opt]['build_dir'], f) }, args[:opt])
end

desc 'Link shared library'
task      :link_shared_lib,       [:opt] do |t, args|
  Rake::Task[File.join(args[:opt]['build_dir'], $shared_lib)].invoke(c_obj_file_list().map { |f| File.join(args[:opt]['build_dir'], f) }, args[:opt])
end

desc 'Print all interesting variables for debugging purposes.'
task      :print_variables do
  file_arrays = {:c_source_files => c_source_files, :c_concat_files => c_concat_files, :c_dep_job => c_dep_job, :c_obj => c_obj}
  puts
  puts 'argv:'
  puts ARGV
  puts
  puts 'global_variables:'
  puts global_variables
  puts
  puts 'Rake::Application:'
  puts Rake.application.options
  puts
  puts 'Number of allowed jobs:'
  puts jobs_param
  puts
  puts 'Options:'
  put_separator
  print_options($opt)
  puts
  puts 'Files:'
  put_separator
  file_arrays.each do |name, file_list|
    #puts 'Name:'
    puts "#{name}:"
    file_list.each do |file|
      #puts 'file:'
      puts "  #{file}"
    end
  end
end

task :help do
  puts ''
  puts 'Tasks:'
  put_separator
  verbose(false) do
    sh 'rake -T'
  end

  puts ''
  puts 'Options:'
  put_separator
  print_available_options
  # verbose(false) do

  # end
end

# We do not use this rule to actually build '.dep' files.
rule /\.dep$/ do |t, args|
  _opt = args.opt
  _dep_filename = t.name.sub('.dep', '.d')
  _obj_filename = t.name.sub('.dep', '.o').sub('c_dep', 'c_obj')
  # If the C source file is newer than the '.d' file
  # rebuild the '.d' file.
  file _dep_filename
  Rake::Task[_dep_filename].invoke
  # We have a valid and actual '.d' file. Invoke the
  # object file rule with the dependencies read from the '.d' file.
  file _obj_filename => comp_dep_2_filelist(_dep_filename) do |t|
    _src_filename = build_to_src_file($opt['build_dir'], t.name).sub('.o', '.c')
    compile_c_object_file(_src_filename, t.name, $opt)
  end
  Rake::Task[_obj_filename].invoke
end

# rule( /\.d$/ => [proc {|task_name| task_name.sub('.d', '.c').sub($opt['build_dir'] + '/', 'src/').gsub('#', '/') }]) do |t|
#   compile_c_dependency_file(t.source, t.name, $obj)
# end


