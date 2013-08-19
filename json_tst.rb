#!/usr/bin/env ruby

require 'json'

timeline = {"timeline" => {"headline" => "Headliner test text"}}
timeline["timeline"]["type"] = "defalut blah"
#timeline["type"] = "default Blah"
#timeline["text"] = "Text Blah"
#timeline["asset"] = {"media" => "http://highpointlowlife.com/images/slimeball_HPLL.jpg Headline"}
#timeline["asset"]["credit"] = "Thor Sideburnz"
#timeline["asset"]["caption"] = "Its Da Mashup, fo!"

#timeline["date"] = []

#timeline["era"] = []
#timeline["era"][0] = {"startDate" => "2011,12,10", "endDate" => "2011,12,11", "headline" => "Erra Headline", "text" => "era txt", "tag" => "taggy"}

#(1..2).each do |n|
#  timeline["date"] << n
#end

p timeline
p timeline.to_json
