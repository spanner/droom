module Droom
  class Ability
    include CanCan::Ability

    def initialize(user)
      user ||= Droom::User.new
      can :create, Droom::Enquiry

      if user.persisted?
        if user.admin?
          can :manage, :all

        elsif !Droom.require_login_permission? || user.permitted?('droom.login')
          can :read, :dashboard
          can :read, Droom::Event
          can :read, Droom::Scrap
          can :read, Droom::Venue
          can :read, Droom::User
          can :read, Droom::Group
          can :read, Droom::Organisation
          can :index, :suggestions

          # This should move into CDR
          can :read, Droom::Document, private: false
          can :read, Droom::Folder, private: false

          # And they can edit themselves
          #
          can :edit, Droom::User, :id => user.id
          can :update, Droom::User, :id => user.id
          # cannot :edit, Droom::User
        
          can :new, [Droom::Email, Droom::Phone, Droom::Address], :user_id => user.id

          # If someone has been allowed to create something, they are generally allowed to edit or remove it.
          # This rule must sit after the user rules because users have no created_by_id column.
          #
          can :manage, [Droom::Event, Droom::Document, Droom::Scrap], :created_by_id => user.id

          # NB confidential events are visible internally but their documents are not.
          if user.privileged?
            can :read, Droom::Document
            can :read, Droom::Folder
          end

          # Then other abilities are determined by permissions. Our permissions are relatively abstract and
          # not closely coupled to Cancan abilities. Here we map them onto more concrete operations.
          #
          if user.permitted?('droom.calendar')
            can :manage, Droom::Event
            can :manage, Droom::EventSet
            can :manage, Droom::Venue
            can :manage, Droom::Invitation
            can :manage, Droom::GroupInvitation
            can :manage, Droom::AgendaCategory
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
          can :create, Droom::DropboxToken
          can :create, Droom::DropboxDocument
          can :create, Droom::MailingListMembership
        end

        can :read, Droom::Scrap

      end
    end
  end
end