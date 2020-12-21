# Droom

Originally, because we were commissioned to create a 'data room' for the Croucher Foundation. The site turned into quite a large cluster of microservices with the data room as its central support, providing user authentication and management and a central administrative overview of the whole cluster.

What remains here is a minimal system for secure document and event distribution. It provides:

* Users & address book
* SSO among data-room-supported applications
* Groups
* Roles and permissions (extendable)
* Calendars and Events 
* Document library with basic access control
* Noticeboard
* Good search functionality

This makes it a good base for most kinds of web tool that involve managing a broad user base. See the [droom_client](https://github.com/spanner/droom_client) gem for ways to support other applications from the data room.


## Status

V0.14 is a thorough tidying up. Windows thrown open, a lot of cruft and clutter blown out including many functions that were commissioned but never much used. In this release:

* Refocus on the core role of the data room: to provide a stable base of community-management.
* Return to the event functionality (after 8 years!) to add more and better integration with google calendars, invitations, etc.
* Nice integration with Chemistry 2 to provide easy publishing to, among and by data room users.
* More documentation


## Installation

In your gemfile:

    gem "droom"

To migrate:

    rake droom:install:migrations
    rake db:migrate


## Copyright

2012-2021 Spanner Ltd.
Released under the same terms as Rails.