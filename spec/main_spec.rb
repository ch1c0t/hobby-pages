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
    expect(response.body).to eq "404. The page named 'nonexist' was not found."
  end

  it 'supports layouts with multiple content sections' do
    response = @conn.get(path: '/with-head')
    doc = Nokogiri.HTML response.body

    text = doc.at_css('title').text
    expect(text).to eq 'Head from with-head'

    text = doc.at_css('p').text
    expect(text).to eq 'main content'
  end

  it 'creates pages with CSS when CSS was supplied' do
    response = @conn.get path: '/with-css'
    doc = Nokogiri.HTML response.body

    text = doc.at_css('style').text
    expect(text).to eq "input {\n  width: 100%; }\n"
  end

  it 'creages pages with JS' do
    response = @conn.get path: '/jspage'
    doc = Nokogiri.HTML response.body

    js_src = doc.at_css('script').attr :src
    expect(js_src).to eq '/jspage.js'

    response = @conn.get path: js_src
    expect(response.body).to eq <<~S
      (function() {
        alert('something');

      }).call(this);
    S
  end

  it 'maps the index template to the root route' do
    response = @conn.get(path: '/')
    doc = Nokogiri.HTML response.body

    text = doc.at_css('p').text
    expect(text).to eq 'index template'
  end
end
