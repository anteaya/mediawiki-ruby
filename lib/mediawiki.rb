$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
#require 'nokogiri'
require 'open-uri'

module Mediawiki
  VERSION = '0.0.3'
  
  def self.search_for_html(wiki_host, term)
    open("http://#{wiki_host}/wiki/Special:Search?search=#{URI.encode(term)}").read
  end

  def self.last_modified(wiki_host, page)
    # can't seem to find evidence that the query will ever return
    # more than one page. Conveniently returns nil on pages that
    # do not exist/throw errors.
    YAML.load(open("http://#{wiki_host}/w/api.php?action=query&titles=#{URI.encode(page)}&format=yaml&prop=info").read)["query"]["pages"][0]["lastrevid"]
  end
end
