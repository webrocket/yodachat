require File.expand_path("../spec_helper", __FILE__)

describe YodaChat::Room do
  subject do
    YodaChat::Room
  end
  
  describe ".create" do
    it "creates new chat room with specified name" do
      room = subject.create("hello1")
      room.should be
      room.id.should == "hello1"
      room.created_at.should be
    end

    context "when gien name is invalid" do
      it "stores proper errors" do
        room = subject.create("%%%")
        room.errors[:id].should_not be_empty
      end
    end
  end

  describe ".find" do
    context "when room exists" do
      before do
        subject.create("hello2")
      end

      it "returns its representation" do
        room = subject.find("hello2")
        room.should be
        room.id.should == "hello2"
      end
    end

    context "when room doesn't exist" do
      it "throws RoomNotFoundError" do
        expect { 
          subject.find("notexists") 
        }.to raise_error(YodaChat::Room::NotFoundError, "Room notexists not found!")
      end
    end
  end

  describe ".find_or_create" do
    context "when room exists" do
      before do
        subject.create("hello3")
      end

      it "returns its representation" do
        room = subject.find_or_create("hello3")
        room.should be
        room.id.should == "hello3"
      end
    end

    context "when room doesn't exist" do
      it "creates it and returns its representation" do
        room = subject.find_or_create("hello4")
        room.should be
        room.id.should == "hello4"
      end
    end
  end
end
