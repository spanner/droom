Feature: Lookup
As an active user
I want to find a contact
So that I can get their contact details

  Scenario: searching
    Given I am an active user
    When I use the search box
    Then I am shown a list of matching contacts
