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
  end

  after(:all) { `kill -9 #{@pid}` }

  it do
    conn = Excon.new 'unix:///', socket: @socket

    doc = Nokogiri.HTML conn.get(path: '/exist').body
    text = doc.at_css('p').text
    expect(text).to eq 'some'

    body = conn.get(path: '/nonexist').body
    expect(body).to eq '404'
  end
end
