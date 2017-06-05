require_relative 'helper'

require 'hobby/pages'
require 'securerandom'
require 'nokogiri'

describe Hobby::Pages do
  before :all do
    @socket = "app.#{SecureRandom.uuid}.socket"
    @pid = fork do
      server = Puma::Server.new described_class.new 'spec/dirs/main'
      server.add_unix_listener @socket
      server.run
      sleep
    end
    sleep 0.01 until File.exist? @socket
    @conn = Excon.new 'unix:///', socket: @socket
  end

  after(:all) { `kill -9 #{@pid}` }

  it 'creates pages for existing templates' do
    doc = Nokogiri.HTML @conn.get(path: '/exist').body

    text = doc.at_css('p').text
    expect(text).to eq 'some'

    text = doc.at_css('title').text
    expect(text).to eq 'Default layout'
  end

  it 'returns 404 for non-existing templates' do
    response = @conn.get(path: '/nonexist')

    expect(response.status).to eq 404
    expect(response.body).to eq '404'
  end

  it 'support layouts with multiple content sections' do
    response = @conn.get(path: '/with-head')
    doc = Nokogiri.HTML response.body

    text = doc.at_css('title').text
    expect(text).to eq 'Head from with-head'

    text = doc.at_css('p').text
    expect(text).to eq 'main content'
  end
end
