#!/usr/bin/env ruby

# RVM support in Rails 3 app for multiple gemsets with Passenger
# config/setup_load_paths.rb

require 'rubygems'
require 'bundler/setup'

Bundler.require

# Define a list of domains that we respond to:
DOMAINS = {
  'isaplonker.uk' => { code: :plonker, teaser: '{{fullname}} is a Plonker', agency: 'Plonkerwatch News', feature: "Need somebody to know they're a plonker?" },
  'isatosser.uk' => { code: :tosser, teaser: "World's Greatest Tosser: {{fullname}}", agency: 'Tosser Times', feature: "Want somebody to know what a tosser they are?" }
}

# Load a list of gendered names
GENDERED_NAMES = {
  0 => File.read('lib/names/male.txt').split(/[\r\n]+/).reject{|n|n.strip == ''},
  1 => File.read('lib/names/female.txt').split(/[\r\n]+/).reject{|n|n.strip == ''}
}

# Set up decoder dictionaries
DICTIONARIES = [
  ['dodgy','daft','naff','sad','shite','skiving','cheeky','nosey','dozy','whinging','stinky','rubbish','barmy','duff','grubby','dim'],
  ['ugly','gormless','bloody','chavvy','shitting','godforsaken','effing','poor','stupid','skanky','fucking','pikey','plastered','nesh','wimpy','buggered'],
  ['muppet','git','moron','pillock','twit','knob','wazzock','berk','ninny','blighter','sod','bellend','wanker','arsehole','divvy','nutter'],
]

# Returns the Host: header from the original request, e.g. "some.body.isaplonker.uk"
def host
  request.env['HTTP_HOST']
end

# Returns the primary domain name based upon the HTTP Host: header (e.g. "isaplonker.uk"),
# assuming that the domain is registered in the DOMAINS constant
def domain
  DOMAINS.keys.select{|d| host =~ /#{d}$/}.first
end

# Returns the part of the domain name that appears before the primary domain
def predomain
  # TODO: do not return leading www., if present
  host.gsub(/\.*#{domain}$/, '')
end

# Returns the name of the victim (derived from the Host: header), if available
# (nil otherwise)
def name
  # Extract name 'parts'
  name_parts = predomain.gsub(/[^\.\-a-z0-9]/, '').split(/\.+/).map(&:capitalize)
  # Handle Irish-style (O'Something) names
  while (index_of_o = name_parts.find_index('O')) && (index_of_o < (name_parts.length - 1))
    name_parts[index_of_o + 1] = "O&#8217;#{name_parts[index_of_o + 1]}"
    name_parts.delete_at(index_of_o)
  end
  # Handle Mc/Mac names
  if name_parts[-1] =~ /^(Ma?c)([a-z])(.+)$/
    name_parts[-1] = "#{$1}#{$2.upcase}#{$3}"
  end
  # Handle hyphenated (e.g. double-barelled names)
  name_parts.each_index do |i|
    name_parts[i].gsub! /(.+-)([a-z])/ do
      "#{$1}#{$2.upcase}"
    end
  end
  # TODO: consider other complicated name rules, such as prepositional parts (von, de, de la)
  #       which should not be capitalised?
  # Return the name parts
  name_parts
end

# Returns the gender of the victim (derived from the path, if available: otherwise
# guessed from the name), for use in generating pronouns. Returns 0 for male pronouns
# (he, him, his, his), 1 for female pronouns (she, her, her, hers), 2 for gender-neutral
# pronouns or where the pronoun can't be guessed (they, them, their, theirs).
def gender
  # Attempt to determine if gender is being specified by the URL
  # TODO: determine gender by preference
  # Failing that, use the first name as a clue
  GENDERED_NAMES.each do |k, v|
    return k if v.include?(name.first)
  end
  # Failing that, use gender-neutral pronouns
  return 2
end

# Returns a full set of pronouns and convenience words, based upon the victim's gender
# Optionally specify a pronoun set (0 = he, 1 = she, 2 = they) to override auto-detection
def pronouns(override_gender = nil)
  [
    {he_she_they: 'he',   him_her_them: 'him',  his_her_their: 'his',   his_hers_theirs: 'his',    man_woman_person: 'man',    boy_girl_child: 'boy',   hes_shes_theyre: "he&#8217;s"},
    {he_she_they: 'she',  him_her_them: 'her',  his_her_their: 'her',   his_hers_theirs: 'hers',   man_woman_person: 'woman',  boy_girl_child: 'girl',  hes_shes_theyre: "shee&#8217;s"},
    {he_she_they: 'they', him_her_them: 'them', his_her_their: 'their', his_hers_theirs: 'theirs', man_woman_person: 'person', boy_girl_child: 'child', hes_shes_theyre: "they&#8217;re"}
  ][override_gender || gender]
end

# Default URL handler
get '/*' do
  @domain, @predomain, @name, @pronouns, @locality = domain, predomain, name, pronouns, nil
  if params['splat'][0] =~ /^([^-]+)-([^-]+)-([^-]+)$/
    # params passed - decode them
    pro, loc = [$1, $2, $3].map{|e| (DICTIONARIES.flatten.index(e) % 16).to_s(2).rjust(4, '0') }.join.scan(/^(.{2})(.{10})$/).flatten.map{|b| b.to_i(2) }
    @pronouns = pronouns(pro - 1) if pro > 0
    @locality = File.read('lib/locations.txt').split("\n").map{|r|r.split('|')}.find{|r| r[2] == loc.to_s}[1]
  end
  if @name.length > 0
    erb :content, layout: DOMAINS[@domain][:code]
  else
    erb :setup, layout: :layout
  end
end

get '/faq' do
  @domain, @predomain = domain, predomain
  erb :faq, layout: :layout
end
