#!/usr/bin/env ruby

# RVM support in Rails 3 app for multiple gemsets with Passenger
# config/setup_load_paths.rb

require 'rubygems'
require 'bundler/setup'

Bundler.require

configure do
end

# Define a list of domains that we respond to:
DOMAINS = {
  'isaplonker.uk' => :plonker,
}

# Returns the Host: header from the original request, e.g. "some.body.isaplonker.uk"
def host
  request.env['HTTP_HOST']
end

# Returns the primary domain name based upon the HTTP Host: header (e.g. "isaplonker.uk"),
# assuming that the domain is registered in the DOMAINS constant
def domain
  return @domain if defined? @domain
  @domain = DOMAINS.keys.select{|d| host =~ /#{d}$/}.first
end

# Returns the name of the victim (derived from the Host: header), if available
# (nil otherwise)
def name
  return @name if defined? @name
  # Extract name 'parts'
  name_parts = host.gsub(/\.*#{domain}$/, '').split(/\.+/).map(&:capitalize)
  # Handle Irish-style (O'Something) names
  while (index_of_o = name_parts.find_index('O')) && (index_of_o < (name_parts.length - 1))
    name_parts[index_of_o + 1] = "O'#{name_parts[index_of_o + 1]}"
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
  @name = name_parts
end

# Returns the gender of the victim (derived from the path, if available: otherwise
# guessed from the name), for use in generating pronouns. Returns 0 for male pronouns
# (he, him, his, his), 1 for female pronouns (she, her, her, hers), 2 for gender-neutral
# pronouns or where the pronoun can't be guessed (they, them, their, theirs).
def gender
  return @gender if defined? @gender
  @gender = 2 # TODO: actually determine
end

# Returns a full set of pronouns and convenience words, based upon the victim's gender
def pronouns
  [
    {he_she_they: 'he',   him_her_them: 'him',  his_her_their: 'his',   his_hers_theirs: 'his',    man_woman_person: 'man',    boy_girl_child: 'boy'},
    {he_she_they: 'she',  him_her_them: 'her',  his_her_their: 'her',   his_hers_theirs: 'hers',   man_woman_person: 'woman',  boy_girl_child: 'girl'},
    {he_she_they: 'they', him_her_them: 'them', his_her_their: 'their', his_hers_theirs: 'theirs', man_woman_person: 'person', boy_girl_child: 'child'}
  ][gender]
end

# Default URL handler
get '/' do
  @domain, @name, @pronouns = domain, name, pronouns
  if @name.length > 0
    erb DOMAINS[@domain]
  else
    erb :setup
  end
end
