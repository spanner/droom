module Droom
  class Ability
    include CanCan::Ability

    def initialize(user)
      user ||= Droom::User.new

      can :create, Droom::Enquiry
      can :read, Droom::Tag

      if user.persisted?
        if user.admin?
          can :manage, :all

        else
          can :update, Droom::User, :id => user.id
          can :new, [Droom::Email, Droom::Phone, Droom::Address], :user_id => user.id
          can :read, :dashboard

          if user.organisation && user.organisation_admin?
            can :manage, Droom::Organisation, id: user.organisation_id
            can :manage, Droom::User, organisation_id: user.organisation_id
          end

          if !Droom.require_internal_organisation? || user.internal?

            if user.data_room_user?
              can :read, :dashboard
              can :index, :suggestions
              can :read, Droom::Event
              can :read, Droom::Calendar
              can :read, Droom::Scrap
              can :read, Droom::Noticeboard
              can :read, Droom::Venue

              unless Droom.config.hide_directory?
                can :read, Droom::User
                can :read, Droom::Group
                can :read, Droom::Organisation
              else
                can :read, Droom::Organisation, id: user.organisation_id
                can :read, Droom::User, organisation_id: user.organisation_id
              end

              # If someone has been allowed to create something, they are generally allowed to edit or remove it.
              # This rule must sit after the user rules because users have no created_by_id column.
              #
              can :manage, [Droom::Event, Droom::Document, Droom::Scrap], :created_by_id => user.id

              # Then other abilities are determined by permissions. Our permissions are relatively abstract and
              # not closely coupled to Cancan abilities. Here we map them onto more concrete operations.
              #
              if user.permitted?('droom.calendar')
                can :manage, Droom::Event
                can :manage, Droom::Venue
              end

              if user.permitted?('droom.directory')
                can :manage, Droom::Group
                can :manage, Droom::Organisation
                can :manage, Droom::User
              end

              if user.permitted?('droom.library')
                can :manage, Droom::Folder
                can :manage, Droom::Document
              end

              if user.permitted?('droom.stream')
                can :create, Droom::Scrap
              end

              if user.permitted?('droom.enquiry')
                can :manage, Droom::Enquiry
              end

              # Some models are purely administrative.
              #
              can :create, Droom::MailingListMembership

              # Confidential events are visible internally but their documents are only visible to 'privileged' users.
              #
              unless user.privileged?
                cannot :read, Droom::Folder, private: true
                cannot :read, Droom::Document, private: true
              end
            end

            can :read, Droom::Scrap

          else
            # What can an external user do? Nothing, by default, but the main app can add permissions.

          end
        end

      elsif Droom::registerable?
        can :create, Droom::User
      end
    end
  end
end