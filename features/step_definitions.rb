require 'securerandom'
require File.expand_path('../../spec/spec_helper', __FILE__)

When /^I create a room called "(.*)"$/ do |room_name|
  @room_name = room_name
  $kosmonaut.expects(:open_channel).with("presence-room-#{@room_name}")
  @create_new_room = CreateNewRoomService.new(@room_name)
  @result, @ok = @create_new_room.as_hash
end

Then /^the room "(.*)" should be persisted$/ do |room_name|
  @ok.should be
  @result.should have_key(:room)
  @join_room = JoinRoomService.new(room_name)
  @result, @ok = @join_room.as_hash
  @ok.should be
  @result.should have_key(:room)
  @result[:room][:name].should == room_name
end

When /^I go to chat room called "(.*)"$/ do |room_name|
  @join_room = JoinRoomService.new(room_name)
  @result, @ok = @join_room.as_hash
end

When /^I go to chat room which does not exist$/ do
  step(%(I go to chat room called "doesnt_exist"))
end

Then /^I should see "(.*)" error$/ do |error|
  @ok.should_not be
  @result.should have_key(:errors)
  @result[:errors].should include(error)
end

When /^I go to chat room with historical conversation$/ do
  step(%(I create a room called "with_history"))
  step(%(I go to chat room called "with_history"))
  step(%(I send a message "The force is strong in you!" as "Marty MacFly"))
end

Then /^I want to see loaded chat history$/ do
  @load_room_history = LoadRoomHistoryService.new(@room_name)
  @result, @ok = @load_room_history.as_hash
  @ok.should be
  @result.should have_key(:history)
  @result[:history].should have(1).item
  step(%(I want to see "Strong in you, the force is!" from "Marty MacFly"))
end

When /^I go to new chat room$/ do
  @room_name = SecureRandom.uuid
  step(%(I create a room called "#{@room_name}"))
end

Then /^I want to see no chat history$/ do
  @load_room_history = LoadRoomHistoryService.new(@room_name)
  @result, @ok = @load_room_history.as_hash
  @ok.should be
  @result.should have_key(:history)
  @result[:history].should be_empty
end

When /^I send a message "(.*)" as "(.*)"$/ do |message, author|
  @message, @author = message, author
  @send_message = SendMessageService.new(@room_name, @message, @author)
  @result, @ok = @send_message.as_hash
  @ok.should be
  @result.should have_key(:message)
end

When /^I send an empty message as "(.*)"$/ do |author|
  @message, @author = "", author
  @send_message = SendMessageService.new(@room_name, @message, @author)
  @result, @ok = @send_message.as_hash
end

Then /^empty message should not be stored$/ do
  @ok.should_not be
  @result.should have_key(:errors)
  @result[:errors].should =~ ["Message can't be blank"]
end

Then /^the message "(.*)" from "(.*)" should be stored in the history$/ do |message, author|
  step(%(I want to see loaded chat history))
  step(%(I want to see "#{message}" from "#{author}"))
end

Then /^I want to see "(.*)" from "(.*)"$/ do |message, author|
  @history_entry = @result[:history].first
  @history_entry[:author].should == author
  @history_entry[:message].should == message
end
