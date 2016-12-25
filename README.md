# Micoroservices health & Version check Script 

  TODO: ruby rpm_cookbook_versions.rb 
        ./healthcheck.rb

  Usage: Please run the script with 'environment' and 'stream' argument to see microservices healthcheck: ./healthcheck.rb dev2 stream
         healthcheck.rb -> will generate an html report with healthchecks message, code, status from the specified environment
         rpm_cookbook_versions.rb -> will generate an html report with rpm and cookbook versions from the specified environment 

  HTML files will be created in the project directory and will have the following format:
       core-health.html
       capture-version.html 

# Configurations

  Configuration files are with <stream>.json
  This contains the microservices, appports and adminports where the scripts will make the call in order to get the healthcheck or RPM version from the environemnt.
 
# Supported Platforms
  
  Linux & Ruby Environment
  Gems: json, net-http-persistent, thread_safe, colorize

# License and Authors

  Author:: Vlad Cenan 
