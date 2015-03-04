require 'json'
require 'sinatra'
require 'faraday'

get '/api/repositories' do
  if expire_cache
    repos = []
    page = 1

    begin
      _repos = get_paginated_repos(page)
      repos.concat _repos
      page += 1
    end until _repos.empty?

    $previous_period = Time.now
    $cache = generate_repositories_json select_display_item(repos)
    $cache
  else
    $cache
  end
end

def expire_cache
  !$cache || went_on_certain_period
end

def went_on_certain_period
  Time.now - $previous_period > 600
end

def connection
  Faraday.new(url: 'https://api.github.com') do |faraday|
    faraday.adapter Faraday.default_adapter
  end
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

def generate_repositories_data(repos)
  repos.map do |repository|
    {
      name: repository['name'],
      description: repository['description'],
      html_url: repository['html_url'],
      star: repository['star'],
    }
  end
end

def generate_repositories_json(repos)
  {
      message: "success",
      errors: [],
      data: generate_repositories_data(repos)
  }.to_json
end
