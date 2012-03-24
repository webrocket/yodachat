require File.expand_path("../spec_helper", __FILE__)

describe YodaChat::StringExt do
  it "provides extension for yodaizing english text" do
    "The force is strong in you!".to_yoda.should == "Strong in you, the force is!"
  end
end
