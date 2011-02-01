require "rubygems"
require "bundler/setup"

require "mechanize"
require "rest_client"
require "yaml"

class SnowWatchr
  
  def initialize(watch_term)
    @agent  = Mechanize.new
    @regex  = /<td.*>(.*#{watch_term}.*)<\/td>/i
    
    # There has got to be a better way to do this
    @config = YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), '..', 'config', 'prowl.yaml'))
    
    check_for_messages
  end
  
  def check_for_messages
    sent_messages = Array.new
    
    loop do
      page = @agent.get("http://www.wtnh.com/subindex/weather/storm_closings")
  
      if @regex.match(page.body)
        messages = page.body.scan(@regex).reject { |m| m.to_s.strip.empty? }
        
        new_messages = messages.select {|m| !sent_messages.include?(m) }
        
        if new_messages.any?
          puts new_messages.join("\n")
          send_message(new_messages.join("\n"))
          
          sent_messages += new_messages
          
          puts "--- #{new_messages.length} new message(s) ---"
        end
      end
  
      sleep 60
    end
  end
  
  def send_message(message)
    RestClient.post 'https://api.prowlapp.com/publicapi/add', 
      :application => 'SnowWatchr', :event => "closing", :description => message,
      :apikey => @config["api_key"], :priority => 2
  end
end

begin
  sw = SnowWatchr.new(ARGV[0]) if ARGV[0]
end