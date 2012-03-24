Feature: Joining a chat

  Scenario: Load history when joined room
    When I go to chat room with historical conversation
    Then I want to see loaded chat history

  Scenario: Join new room
    When I go to new chat room
    Then I want to see no chat history

  Scenario: Join not existing room
    When I go to chat room which does not exist
    Then I should see "Room doesn't exist" error