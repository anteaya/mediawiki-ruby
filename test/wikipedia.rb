#!/usr/bin/env ruby
W = "http://en.wikipedia.org"

# type
# echo @user, @password = "foo", "bar" > test/private.rb
require "#{File.dirname(__FILE__)}/../test/private.rb"

def esc(foo)
  URI::escape(foo)
end

def mw
  Mediawiki
end

def login
  mw::login(W, @user, @password) 
end

def edit
  mw::edit(W, "User:Hif/foo", "yet another test #{Time.now}", "test", login)
end

def html
  mw::search_for_html(W, "Foobar")
end

def markup
  mw::markup(W, "Foobar")
end
