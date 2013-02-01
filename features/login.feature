Feature: Login
As an active user
I want to login
So that I can view private information

  Scenario: user login
    Given I am an active user
    When I log in
    Then I should be logged in