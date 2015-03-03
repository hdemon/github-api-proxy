require 'json'
require 'sinatra'
require 'faraday'

get '/api/repositories' do
  repos = []
  page = 1

  begin
    _repos = get_paginated_repos(page)
    repos.concat _repos
    page += 1
  end until _repos.empty?

  generate_display_item_json select_display_item(repos)
end

def connection
  Faraday.new(url: 'https://api.github.com') do |faraday|
    faraday.adapter Faraday.default_adapter
  end
end

def get_paginated_repos(page)
  response = connection.get "/users/#{ENV['USER_NAME']}/repos?type=owner&page=#{page}&access_token=#{ENV['ACCESS_TOKEN']}"
  JSON.parse response.body
end

def select_display_item(repos)
  repos.select {|repository| repository['description'].match(/\s{3}\Z/) }
end

def generate_display_item_json(repos)
  repos.map do |repository|
    {
      name: repository['name'],
      description: repository['description'],
      html_url: repository['html_url'],
      star: repository['star'],
    }
  end.to_json
end
