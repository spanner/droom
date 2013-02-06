Feature: Create document
As a logged in user
I want to add a document
So I can share it with other users

  Scenario: adding a document
    Given I am a logged in user
    When I add a document
    Then the document should be created
