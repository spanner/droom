Feature: Create event
As a logged in user
I want to add an event
So users can see details about the event

  Scenario: creating an event as a user
    Given I am a logged in administrator
    When I add an event
    Then the event should be created

