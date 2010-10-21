require 'rubygems'
require 'sinatra'
require 'haml'
require 'net/http'

configure do
  require 'memcached'
  CACHE = Memcached.new
end

get '/stylesheet.css' do
  content_type "text/css",  :charset => "utf-8"
  sass :stylesheet
end

get '/' do
  @now = Time.now
  
  begin
    @last = CACHE.get('time')
  rescue Memcached::NotFound
    CACHE.set('time', Time.now - 1000)
  end
    
  
  if((CACHE.get('time') + 300) < @now)
    CACHE.set('time', @now)
    @last = @now
    
    begin
      res = Net::HTTP.get_response(URI.parse("http://minecraft.net/"))
      if (res.code =~ /2|3\d{2}/)
        @main = "is up!"
      else
        @main = "is down, be patient."
      end
    rescue Exception
      @main = "is down, be patient."
    end
    
    CACHE.set('main', @main)
  
    begin
      res = Net::HTTP.get_response(URI.parse("http://www.minecraftwiki.net/ping"))
  
      if (res.code =~ /2|3\d{2}/)
        @wiki = "is up!"
      else
        @wiki = "is down, be patient."
      end
    rescue Exception
      @wiki = "is down, be patient."
    end
    
    CACHE.set('wiki', @wiki)
  
    begin
      res = Net::HTTP.get_response(URI.parse("http://www.minecraftforums.net/ping"))
    
      if (res.code =~ /2|3\d{2}/)
        @forums = "is up!"
      else
        @forums = "is down, be patient."
      end
    rescue Exception
        @forums = "is down, be patient."
      end
    
    CACHE.set('forums', @forums)
  else
    @main = CACHE.get('main')
    @wiki = CACHE.get('wiki')
    @forums = CACHE.get('forums')
  end
  
  haml :index
  
end