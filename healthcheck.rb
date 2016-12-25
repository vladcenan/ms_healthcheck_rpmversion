#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'net/http'
require 'thwait'
require 'colorize'

script=$0
if ARGV.length != 2 then
  puts "\nUsage:" 
  puts "Please run the script with 'environment' and 'stream' argument to see microservices healthcheck: #{script} prod1 stream\n"
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
  h[thread_id] = "<html><body><h1> #{microservice} </h1></body></html>"
  port = data_hash["#{microservice}"]['adport']
  h[thread_id] << "\n<html><body><h3> Port: #{port} </h3></body></html>\n"

  nodes = "knife search 'chef_environment:#{env} AND recipe:#{microservice}' -i 2>&1 | sed '1,2d'"
  node = %x[ #{nodes} ].split 
  node.each do |n|
    begin
      h[thread_id] << "\n<html><body><h4> Node: #{n} </h4></body></html>\n"
      uri = URI("http://#{n}:#{port}/healthcheck?count=10")
      res = Net::HTTP.get_response(uri)
      status = Net::HTTP.get(uri)
      if res.code == '200'
        h[thread_id] << "<font size='3' color='green'> #{res.code} </font>"
        h[thread_id] << status
        h[thread_id] << res.message
      else
        h[thread_id] << "<font size='3' color='red'> #{res.code} </font>"
        h[thread_id] << "<font size='3' color='red'> #{status} </font>"
        h[thread_id] << "<font size='3' color='red'> #{res.message} </font>"
      end
    rescue => e
      h[thread_id] << "ReadTimeout Error"
      next
    end
  end

#  rescue Net::ReadTimeout
  rescue => e
    h[thread_id] << "ReadTimeout Error"
    next 
  end
  end
end

threads.each do |thread|
  thread.join
end

ThreadsWait.all_waits(*threads)
h.values.join("\n")

somefile = File.open("#{srv}-health.html", "w")
somefile.puts "<html><body><h3> Environment: #{env} </h3></body></html>"
somefile.puts h.values.join("\n")
somefile.close  
