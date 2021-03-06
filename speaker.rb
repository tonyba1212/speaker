require 'sinatra'
require 'sass'
require 'ap'
require 'thread'

FEMALE_VOICES = [
  "Agnes",
  "Kathy",
  "Princess",
  "Vicki",
  "Victoria"
]

MALE_VOICES = [
  "Bruce",
  "Fred",
  "Junior",
  "Ralph"
]

VOICES = MALE_VOICES + FEMALE_VOICES

mutex = Mutex.new

set :haml, :format => :html5

get '/speaker' do
  haml :say
end

# render stylesheets
get '/stylesheets/:name.css' do
 content_type 'text/css', :charset => 'utf-8'
 scss :"stylesheets/#{params[:name]}"
end

get '/volume/:value' do
  # obtain the current volume
  if params[:value] == "current"
    `cat volume`
  # set the volume
  else
    current_volume = `cat volume`
    current_volume = current_volume.to_i || 0
    volume = case params[:value]
    when "max"
      10
    when "mute"
      0
    when "min"
      0
    when "up"
      if current_volume == 10
        10
      else
        current_volume + 1
      end
    when "down"
      if current_volume == 0
        0
      else
        current_volume - 1
      end
    else
      params[:value].to_i
    end
  
    puts "Volume is now #{volume}"
    # save the volume in a stateful file
    system "echo #{volume} > volume"
    system "osascript -e \"set Volume #{volume}\""
  end
end


post '/say' do
  # sadly, this mutex doesn't work WHY???
  mutex.synchronize {
    voice = params[:voice] || VOICES[request.ip.split(".").last.to_i % VOICES.length] 
    text = params[:text][0..50]
    
    puts "#{voice}: #{text}"
    
    cmd = "say"
    cmd << " -v \"#{voice}\"" if voice
    cmd << " \"#{text}\""
    system cmd
  }
end
