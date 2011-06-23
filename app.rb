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
      if((CACHE.get('time') + 300) < @now && CACHE.get('json') !=  nil)
        return CACHE.get('json').to_json
      end
    CACHE.set('time', @now)
    @last = @now
    result = {}
    result[:results] = {}
    result[:results][:minecraft] = get_code("http://minecraft.net")
    result[:results][:wiki] = get_code("http://minecraftwiki.net")
    result[:results][:forum] = get_code("http://minecraftfourm.net")
    result[:results][:login] = get_code("https://login.minecraft.net")
    result[:check_time] = @now.to_s
    result[:next_check] = CACHE.get('time') + 300
    CACHE.set('json', result)
    result.to_json
end

get '/' do
  check(false)
  haml :index 
end


def get_code(site)
  Timeout::timeout(5) do
    begin
      res = Net::HTTP.get_response(URI.parse(site))
      return res.code
    rescue Exception
      return "502"
    end
  end
end

def get_status(site)
  begin
    if (get_code(site) =~ /^2|3\d{2}$/)
      return "is up!"
    else
      return "is down, be patient."
    end
  rescue Exception
    return "is down, be patient."
  end
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

    @main = get_status("http://minecraft.net")
    CACHE.set('main', @main)

    @wiki = get_status("http://minecraftwiki.net")
    CACHE.set('wiki', @wiki)

    @forums = get_status("http://minecraftforum.net")    
    CACHE.set('forums', @forums)

    @login = get_status("https://login.minecraft.net")
    CACHE.set('login', @login)
  else
    @main = CACHE.get('main')
    @wiki = CACHE.get('wiki')
    @forums = CACHE.get('forums')
    @login = CACHE.get('login')
  end
end