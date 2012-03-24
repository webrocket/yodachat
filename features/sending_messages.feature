Feature: Sending messages

  Scenario: Sending message in the room
    When I go to new chat room
    And I send a message "The force is strong in you!" as "Marty MacFly"
    Then the message "Strong in you, the force is!" from "Marty MacFly" should be stored in the history