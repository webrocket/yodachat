require File.expand_path("../../spec_helper", __FILE__)
require 'webrocket/client'

describe WebRocket::Client do
  subject do
    WebRocket::Client
  end

  describe "initialization" do
    context "when invalid protocol given" do
      it "raises UnsupportedProtocolError" do
        expect { 
          subject.new("http://foobar.com/")
        }.to raise_error(WebRocket::UnsupportedProtocolError)
      end
    end
  end
  
  describe "#connect" do
    context "when can't connect to the server" do
      it "raises timeout error" do
        pending
        #conn = subject.new("wr://127.0.0.1:9777/vhost", :timeout => 1)
        #expect { conn.connect }.to raise_error(Timeout::Error)
      end
    end

    context "when invalid credentials" do
      it "raises unauthorized error" do
        conn = subject.new("wr://wronguser:wrongpass@127.0.0.1:9773/vhost")
        expect { conn.connect }.to raise_error(WebRocket::ClientError, "Error 401: Unauthorized")
      end
    end

    context "when everything's ok" do
      it "connects to the server and returns alive connection" do
        conn = subject.new("wr://user:pass@127.0.0.1:9773/vhost")
        conn.connect
        conn.should be_active
        conn.disconnect
      end
    end
  end

  describe "#disconnect" do
    it "closes connection" do
      # already tested in other places
    end
  end

  let(:conn) do
    subject.new("wr://user:pass@127.0.0.1:9773/vhost")
  end

  describe "#active?" do
    it "returns false when connection is not active" do
      conn.should_not be_active
    end

    it "returns true when connection is active" do
      conn.connect
      conn.should be_active
      conn.disconnect
    end

    it "returns false after disconnecting" do
      conn.connect
      conn.disconnect
      conn.should_not be_active
    end
  end

  describe "when #on_event set" do
    it "handles incoming events when set" do
      pending
    end
  end

  describe "when #on_error set" do
    it "handles errors when set" do
      pending
    end
  end

  describe "#broadcast!" do
    it "sends broadcast message to the server" do
      conn.connect
      conn.broadcast!("foo", "hello", {"who" => "world"})
      pending
    end
  end
end
