Feature: Creating new room

  Scenario: Create a room with random name
    When I create a room called "hello"
    Then the room "hello" should be persisted
 
  Scenario: Create a room with empty name
    When I create a room called ""
    Then I should see "Name can't be blank" error
    