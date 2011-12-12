require File.expand_path("../spec_helper", __FILE__)

describe YodaChat::Room do
  subject do
    YodaChat::Room
  end
  
  describe ".create!" do
    it "creates new chat room with specified name" do
      room = subject.create!("hello")
      room.id.should == "hello"
      room.created_at.should be
    end
  end

  describe ".find" do
    context "when room exists" do
      before do
        subject.create!("hello")
      end

      it "returns its representation" do
        room = subject.find("hello")
        room.id.should == "hello"
      end
    end

    context "when room doesn't exist" do
      it "throws RoomNotFoundError" do
        expect { 
          subject.find("notexists") 
        }.to raise_error(YodaChat::RoomNotFoundError, "The `notexists` room doesn't exist!")
      end
    end
  end

  describe ".find_or_create!" do
    context "when room exists" do
      before do
        subject.create!("hello")
      end

      it "returns its representation" do
        room = subject.find_or_create!("hello")
        room.id.should == "hello"
      end
    end

    context "when room doesn't exist" do
      it "creates it and returns its representation" do
        room = subject.find_or_create!("other")
        room.id.should == "other"
      end
    end
  end
end
