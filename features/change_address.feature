Feature: Change address
As a user
I want to change my address
So I can receive correspondence at a different address

  Scenario: user login
    Given a logged in user
    When I visit the edit user page
    And change my address
    Then my address should have changed
    And I should be on the dashboard
