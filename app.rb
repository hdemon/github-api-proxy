require 'json'
require 'uri'
require 'base64'
require 'sinatra'
require 'sinatra/cross_origin'
require 'faraday'
require './cache'
require './response'
require "pry"

configure do
  enable :cross_origin
end

$cache = {}

get '/api/repositories' do
  $cache[:repositories] = $cache[:repositories] || Cache.new

  if $cache[:repositories].expire?
    repos = []
    page = 1

    begin
      _repos = get_paginated_repos(page)
      repos.concat _repos
      page += 1
    end until _repos.empty?

    $cache[:repositories].expire
    $cache[:repositories].content = generate_repositories_data select_display_item(repos)
  end

  response = Response.new
  response.data = $cache[:repositories].content
  response.render
end

get '/api/articles' do
  $cache[:article_index] = $cache[:article_index] || Cache.new
  if $cache[:article_index].expire?
    $cache[:article_index].content = generate_article_index_data get_articles
  end

  response = Response.new
  response.data = $cache[:article_index].content
  response.render
end

get '/api/articles/:name' do
  $cache[:articles] = $cache[:articles] || {}
  $cache[:articles][params[:name]] = $cache[:articles][params[:name]] || Cache.new
  if $cache[:articles][params[:name]].expire?
    $cache[:articles][params[:name]].content = generate_article_data get_article params[:name]
  end

  response = Response.new
  response.data = $cache[:articles][params[:name]].content
  response.render
end

def connection
  Faraday.new(url: 'https://api.github.com') do |faraday|
    faraday.adapter Faraday.default_adapter
  end
end

def get_articles
  url = "/repos/#{ENV['USER_NAME']}/hdemon-articles/contents/articles"
  if ENV['ACCESS_TOKEN']
    url += "?access_token=#{ENV['ACCESS_TOKEN']}"
  end

  response = connection.get url
  JSON.parse response.body
end

def get_article(name)
  url = "/repos/#{ENV['USER_NAME']}/hdemon-articles/contents/articles/#{name}"
  if ENV['ACCESS_TOKEN']
    url += "?access_token=#{ENV['ACCESS_TOKEN']}"
  end

  response = connection.get URI.encode url
  JSON.parse response.body
end

def get_paginated_repos(page)
  url = "/users/#{ENV['USER_NAME']}/repos?type=owner&page=#{page}"
  if ENV['ACCESS_TOKEN']
    url += "&access_token=#{ENV['ACCESS_TOKEN']}"
  end

  response = connection.get url
  JSON.parse response.body
end

def select_display_item(repos)
  repos.select {|repository| repository['description'].match(/\s{3}\Z/) }
end

def generate_article_index_data(articles)
  articles.map do |article|
    {
      name: article['name'],
      title: article['name'].match(/\A.+(?=\_)/),
      publish_date: article['name'].match(/(?<=\_)[0-9\-]{10}/)[0].gsub(/\-/, '/')
    }
  end
end

def generate_article_data(data)
  {
    name: data['name'],
    content: Base64.decode64(data['content']).force_encoding("UTF-8"),
  }
end

def generate_repositories_data(repos)
  repos.map do |repository|
    {
      name: repository['name'],
      description: repository['description'],
      html_url: repository['html_url'],
      stargazers_count: repository['stargazers_count'],
    }
  end
end
