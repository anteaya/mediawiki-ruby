$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'rest_client'
require 'cgi'
require 'yaml'

module Mediawiki
  VERSION = '0.0.4'

  def self.search_for_html(wiki_host, term)
    RestClient.get "#{wiki_host}/wiki/Special:Search?search=#{URI.encode(term)}" 
  end
  
  def self.article_properties(wiki_host, page)
    YAML.load(RestClient.get api_url(wiki_host, "query", "titles=#{URI.encode(page)}", "prop=info"))
  end

  def self.last_modified(wiki_host, page)
    # can't seem to find evidence that the query will ever return
    # more than one page. Conveniently returns nil on pages that
    # do not exist/throw errors.
    self.article_properties(wiki_host, page)["query"]["pages"][0]["lastrevid"]
  end

  def self.login(wiki_host, user, password)
    result = YAML.load RestClient.post api_url(wiki_host, "login"), :lgname => user, :lgpassword => password

    return nil unless result["login"]["result"] == "Success"
    result = result["login"]
    prefix = result["cookieprefix"]

    # http://www.mediawiki.org/wiki/API:Login
    # And, lo, I pronounce thee
    "#{prefix}UserName=#{result["lgusername"]}; " +
      "#{prefix}UserId=#{result["lguserid"].strip}; " +
      "#{prefix}Token=#{result["lgtoken"]}; "+
      "#{prefix}_session=#{result["sessionid"]}"
  end

  # currently, #edit & #markup are less than awesome: these will 
  # fail silently if the title you're looking up has any redirects, 
  # and they will not warn you about disambiguations. Ideally,
  # (aka later on), these methods will only take pageids after a 
  # lookup and/or disambiguation is performed

  def self.edit(wiki_host, title, text, summary, cookie)
    e_title = URI::escape(title)

    token = YAML.load(RestClient.get api_url(wiki_host, "query", "prop=info%7Crevisions", "intoken=edit", "titles=#{e_title}"), :Cookie => cookie)["query"]["pages"][0]["edittoken"]

    e_token, e_text, e_summary = CGI::escape(token), CGI::escape(text), CGI::escape(summary)

    server_response = RestClient.post(api_url(wiki_host, "edit", "title=#{e_title}", "text=#{e_text}", "token=#{e_token}"), "", :Cookie => cookie)
  
    # basically, the only way for this to fail is if you have a wrong cookie
    return nil unless server_response.include?("Success")
    server_response
  end

  # http://www.mediawiki.org/wiki/API:Query_-_Properties#revisions_.2F_rv
  def self.markup(wiki_host, title)
    response = YAML.load(RestClient.get(api_url(wiki_host, "query", "prop=revisions", "titles=#{URI::escape(title)}", "rvprop=content")))
    
    # we only request one page, and only one revision
    # returns nil on errors
    response["query"]["pages"][0]["revisions"][0]['*']
  end

 private

  def self.api_url(wiki_host, action, *options)
    if options.first.is_a? Hash
      options = options.first.collect do |key, value|
        "#{key}=#{CGI::escape(value)}"
      end
    end
    
    # combine the options with an ampersand
    extra_url_params_string = options.collect { |i| "&" + i }.to_s
    
    return "#{wiki_host}/w/api.php?action=#{action}&format=yaml" + extra_url_params_string
  end
end
