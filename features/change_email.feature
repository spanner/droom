Feature: Change email
As a user
I want to change my email address
So I can receive notifications to a different address

  Scenario: user login
    Given a logged in user
    When I change my email
    Then my email should have changed
    And I should be on the dashboard