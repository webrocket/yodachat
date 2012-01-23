require File.expand_path("../spec_helper", __FILE__)

describe YodaChat::Message do
  let :room do
    YodaChat::Room.find_or_create("one")
  end

  describe ".create" do  
    it "creates new message and transforms it to yoda" do
      msg = room.messages.create(:message => "The force is strong in you", :author => "Yoda")
      msg.message.should == "Strong in you, the force is"
      msg.author.should == "Yoda"
    end
  end

  describe ".recent" do
    let :room do
      YodaChat::Room.find_or_create("two")
    end

    before do
      3.times { |i|
        room.messages.create(:message => "Hello #{i}", :author => "Anonymous #{i}")
      }
    end

    it "displays list of the recent messages" do
      room.messages.recent.should have(3).items
    end

    context "when result is limited" do
      it "displays only specified amount of messages" do
        room.messages.recent(1).should have(1).items
      end
    end
  end

  describe "#to_hash" do
    it "returns message as a hash" do
      msg = room.messages.new(:author => "Yoda", :message => "Hello!", :posted_at => Time.now)
      hash = msg.to_hash
      hash[:author].should == "Yoda"
      hash[:message].should == "Hello!"
      hash[:posted_at].should be
    end
  end
end
