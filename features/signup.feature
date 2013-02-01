Feature: Sign up
As an invited user
I want to activate my account
So that I can login

  Scenario: user sign up
    Given I am an invited user
    When I follow the invitation email link
    And I fill in the welcome form
    Then I should be logged in
