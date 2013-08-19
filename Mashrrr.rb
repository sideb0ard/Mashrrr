#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'haml'
require 'yaml'
require 'date'

############################################
# CONF SECTION _ API KEYZ AND URLZ #####

configfile = YAML.load_file('conf/apikeyz.yml')

# LASTFM SHIZZLES
@lfm_api_key = configfile["lastfm_apikey"]
@userName = "sideb0ard"
@lastfmapi = "http://ws.audioscrobbler.com/2.0/"

# Secret API 
@secretapi = configfile["secretapi"]
@secretapi_api = configfile["secretapi_api"]
@secretapi_u = configfile["secretapi_u"]
@secretapi_p = configfile["secretapi_p"]

######################################

# TO STORE THE FINAL OUTPUT
@jsonDataObject = []

def makeJson
  timeline = {"timeline" => { "headline" => "Sideb0ard's Lastfm => OA mashuprrr"}}
  timeline["timeline"]["type"] = "default"
  timeline["timeline"]["text"] = "Mashing Up Da Future Of Musicz"
  timeline["timeline"]["asset"] = {"media" => "http://3.bp.blogspot.com/-aAQQwpf-VUo/TncMRHilvnI/AAAAAAAAAdg/NtBRf_pqhbg/s1600/thor-portrait.jpg"}
  timeline["timeline"]["asset"]["credit"] = "Thor Sideburnz"
  timeline["timeline"]["asset"]["caption"] = "Its Da Mashup, fo!"

  timeline["timeline"]["date"] = @jsonDataObject

  timeline["timeline"]["era"] = []
  timeline["timeline"]["era"][0] = {"startDate" => "2005,12,10", "endDate" => "2013,12,11", "headline" => "Erra Headline", "text" => "era txt", "tag" => "taggy"}

	File.open("public/timedata.json","w") do |f|
	  f.write(timeline.to_json)
	end
end

############################################
## FIRST STAGE - GRAB LIST OF LASTFM WEEKLY CHARTS

def grabCharts(userName)
  chartz = JSON.parse(open(@lastfmapi + "?method=user.getweeklychartlist&user=" + @userName + "&api_key=" + @lfm_api_key + "&format=json").read)
  #chartz["weeklychartlist"]["chart"].take(20).each {|c|
  chartz["weeklychartlist"]["chart"].each {|c|
    p c["from"]
    p c["to"]
    begin
      grabChartData(c["from"],c["to"])
    rescue
      puts "Something wrong in grab charts - skipping.."
      next
    end
  }
  # ALL DONE - MAKE JSON NOW
  makeJson
end

## GRAB INDIVIDUAL CHARTS
def grabChartData(fromTime,toTime)
  scrobz_url = @lastfmapi + "?method=user.getweeklyartistchart&user=" + @userName + "&api_key=" + @lfm_api_key + "&from=#{fromTime}&to=#{toTime}&format=json"
	# puts scrobz_url
  begin
	  scrobz = JSON.parse(open(scrobz_url).read)
  rescue
    puts "Problem getting scrobbles - skipping this week..."
    return
  end
  # p scrobz
	
	## 2ND STAGE - FOR EACH, GET TOP ARTIST FOR EVERY WEEK THEN A PARTICLE FOR TOP

  if scrobz["weeklyartistchart"]["artist"].nil? then
    return
  end
	
	catch (:foundArtist) {
	  scrobz["weeklyartistchart"]["artist"].each {|a|
		  next if a["playcount"].to_i < 5
		  puts "Processing Weekly Charts -- #{a["name"]}"
		
		  #TODO# - Add MemCache 
		
		  # SEARCH OA FOR ARTIIST ID BASED ON LASTFM USER
		  a_id_search = JSON.parse(open(@secretapi + "/api/artists/autosuggest?results=1&format=json&name=" + URI::encode(a["name"]), :http_basic_authentication => [@secretapi_u, @secretapi_p]).read)
		  next if a_id_search["response"]["artists"][0].to_s.empty?
		  a_id = a_id_search["response"]["artists"][0]["id"]
		  aura = "#{@secretapi_api}" + "#{a_id}"
		  puts aura # API AURA ADDRESS
		
		  # GRAB PARTICLES WITH ARTIST ID
		  a_particles_search = JSON.parse(open(aura).read)
		  puts a_particles_search["particles"].count
		
		  if a_particles_search["particles"].count < 1 then
		    p "No Particle -- Skipping to next"
		    # NO PARTICLES _  HIT THE SITE SO WE FILL IT FOR NEXT TIME
		    open(@secretapi + "/artist/" + "#{a_id}", :http_basic_authentication => [@secretapi_u, @secretapi_p])
		    next
		  else
		    a_particles_search["particles"].each {|p| 
	        p.each { |k, v|
	          if k == "media" && v.size > 0 then #// SHOULD BE AN IMAGE
	            img_media_file = (v.max_by { |vl| vl["width"] })["url"]
              startDate = Time.at(fromTime.to_i).to_datetime
              p startDate
              #p "START :: #{startDate}"
              endDate = Time.at(toTime.to_i).to_datetime
              #p "END :: #{endDate}"
	            chartEntry = {
	              "startDate" =>  "#{startDate.year},#{startDate.month},#{startDate.day}",
	              "endDate" =>  "#{endDate.year},#{endDate.month},#{endDate.day}",
	              "headline" => "#{a["name"]}",
	              "text" => "Lastfm, top artist of w/b #{Time.at(1371988800)}",
	              "tag" => "",
	              "asset" => {
	                "media" => "#{img_media_file}",
	                "thumbnail" =>  "",
	                "credit" => "",
	                "caption" => ""
	              }
	            }
              @jsonDataObject << chartEntry
	            p chartEntry.to_json
	            throw :foundArtist
	          end
	        }
		    }
	
		  end
		  puts ""
	  }
	}
end

# MAIN CALL STARTS HERE
grabCharts(@userName)

