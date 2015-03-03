# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe "App" do
  include Rack::Test::Methods
  def app
    @app ||= Sinatra::Application
  end

  describe "web api" do
    describe "/api/repositories" do
      before { get '/api/repositories' }
      it "should respond normal response" do
        expect(last_response).to be_ok
      end

      it "should return json of specified repositories" do
      end
    end
  end
end
