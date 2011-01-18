require 'rubygems'
require 'sinatra'
require 'haml'
require 'net/http'
require 'json'
require 'sass'

configure do
  require 'memcached'
  CACHE = Memcached.new
end

get '/stylesheet.css' do
  content_type "text/css",  :charset => "utf-8"
  sass :stylesheet
end

get '/status.json' do
  @now = Time.now
  if((CACHE.get('time') + 300) < @now || CACHE.get('json') == nil)
    CACHE.set('time', @now)
    @last = @now
    result = {}
    result[:results] = {}
    result[:results][:minecraft] = get_code("http://minecraft.net")
    result[:results][:wiki] = get_code("http://minecraftwiki.net")
    result[:results][:forum] = get_code("http://minecraftfourm.net")
    result[:check_time] = @now.to_s
    result[:next_check] = CACHE.get('time') + 300
    CACHE.set('json', result)
  else
    CACHE.get('json').to_json
  end
end

get '/' do
  check(false)
  haml :index 
end


def get_code(site)
  res = Net::HTTP.get_response(URI.parse(site))
  res.code
end

def check(force)
  @now = Time.now
  
  begin
    @last = CACHE.get('time')
  rescue Memcached::NotFound
    CACHE.set('time', Time.now - 1000)
  end
    
  
  if((CACHE.get('time') + 300) < @now && force == false)
    CACHE.set('time', @now)
    @last = @now
    
    begin
      if (get_code("http://minecraft.net") =~ /^2|3\d{2}$/)
        puts get_code("http://minecraft.net")
        @main = "is up!"
      else
        @main = "is down, be patient."
      end
    rescue Exception
      @main = "is down, be patient."
    end
    
    CACHE.set('main', @main)
  
    begin
      if (get_code("http://minecraftwiki.net") =~ /^2|3\d{2}$/)
        @wiki = "is up!"
      else
        @wiki = "is down, be patient."
      end
    rescue Exception
      @wiki = "is down, be patient."
    end
    
    CACHE.set('wiki', @wiki)
  
    begin
      if (get_code("http://minecraftforum.net") =~ /^2|3\d{2}$/)
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
end