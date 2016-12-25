#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'net/http'
require 'thwait'

script = $PROGRAM_NAME
if ARGV.length != 2
  puts "\nUsage:"
  puts "Please run the script with 'environment' and 'stream' argument to see rpm & cookbook versions: #{script} prod1 stream\n"
  puts "\n"
  exit
end

env, srv = ARGV
puts "Environment: #{env}"
puts "Service file: #{srv}.json"

file = File.read("./#{srv}.json")
data_hash = JSON.parse(file)

h = {}
threads = []
service = data_hash.keys
service.each do |microservice|
  threads << Thread.new do
    thread_id = Thread.current.object_id.to_s(36)
    begin
      h[thread_id] = ''
      port = data_hash["#{microservice}"]['apport']

      nodes = "knife search 'chef_environment:#{env} AND recipe:#{microservice}' -i 2>&1 | sed '1,2d'"
      node = ` #{nodes} `.split
      node.each do |n|
        begin
          h[thread_id] << "\n<html><body><h4> #{n} </h4></body></html>"
          chef_hash = JSON.parse(`knife environment show #{env} -Fj`)
          node_hash = JSON.parse(`knife node show #{n} -Fj`)
          cache_hash = "knife ssh 'name:#{n}' 'grep -ri 'version' /var/chef/cache/cookbooks/#{microservice}/metadata.json' | awk '{print $3}' | tr -cd '[0-9].'"
          uri = URI("http://#{n}:#{port}/service-version")
          status = Net::HTTP.get(uri)
          data_hash = JSON.parse(status)
          if data_hash.include?('version')
            version = data_hash['version']
          elsif chef_hash['default_attributes'].include?("#{microservice}") && chef_hash['default_attributes']["#{microservice}"].include?('version')
            version = chef_hash['default_attributes']["#{microservice}"]['version']
          elsif node_hash['normal'].include?("#{microservice}") && node_hash['normal']["#{microservice}"].include?('version')
            version = node_hash['normal']["#{microservice}"]['version']
          else
            version = 'NA'
          end
          h[thread_id] << "<html><body> #{microservice}:#{version} <html><body>"
          if chef_hash['cookbook_versions'].include?("#{microservice}")
            cookbook = chef_hash['cookbook_versions']["#{microservice}"]
          elsif node_hash['normal'].include?("#{microservice}") && node_hash['normal']["#{microservice}"].include?('cookbook_version')
            cookbook = node_hash['normal']["#{microservice}"]['cookbook_version']
          else
            cookbook = ` #{cache_hash} `
          end
          h[thread_id] << "<html><body> Cookbook:#{cookbook} <html><body>"
        rescue StandardError
          h[thread_id] << 'ReadTimeout Error'
          next
        end
      end

    rescue StandardError
      h[thread_id] << 'ReadTimeout Error'
      next
    end
  end
end

threads.each(&:join)

ThreadsWait.all_waits(*threads)
h.values.join("\n")

somefile = File.open("#{srv}-version.html", 'w')
somefile.puts "<html><body><h3> Environment: #{env} </h3></body></html>"
somefile.puts h.values.join("\n")
somefile.close
