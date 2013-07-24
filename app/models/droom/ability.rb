module Droom
  class Ability
    include CanCan::Ability

    def initialize(user)
      if user.admin?
        # An admin flag on the user table overrides this whole mechanism to make all things possible.
        #
        can :manage, :all

      else
        # Otherwise, most items are visible to all.
        #
        can :read, Droom::Event
        can :read, Droom::User
        can :read, Droom::Scrap
        can :read, Droom::Venue
        
        # except folders, which when confidential are only visible to people associated with
        # their holder (ie group member or event attender).
        #
        #todo: add personal-access condition: folder must be non-private or joined to us through holder.
        # we may need to retain the personal-folder mechanism for this but the labelling will change.
        #
        can :read, Droom::Folder
        
        # If someone has been allowed to create something, they are always allowed to edit or remove it.
        #
        can :manage, :all, :created_by_id => user.id
        
        # And they can edit themselves
        #
        can :update, Droom::User, :id => user.id
        
        # Then other abilities are determined by permissions. Permissions here are relatively abstract and 
        # not closely coupled to Cancan abilities. Here we make them concrete.
        #
        if user.permitted?('droom.calendar')
          can :create, Droom::Event
          can :create, Droom::EventSet
          can :create, Droom::Venue
          can :create, Droom::Invitation
          can :create, Droom::GroupInvitation
          if user.permitted?('droom.attach')
            # todo: scope to folders attached to own events
            can :create, Droom::AgendaCategory
            can :create, Droom::Document 
          end
        end

        if user.permitted?('droom.directory')
          can :create, Droom::Group
          can :create, Droom::Organisation
          can :create, Droom::User
        end
        
        if user.permitted?('droom.library')
          can :create, Droom::Folder
          can :create, Droom::Document
        end
        
        if user.permitted?('droom.stream')
          can :create, Droom::Scrap
        end

        if user.permitted?('droom.pages')
          can :create, Droom::Page
        end

        # Some models are purely administrative.
        #
        can :create, Droom::DropboxToken
        can :create, Droom::DropboxDocument
        can :create, Droom::MailingListMembership
        
      end
    end
  end
end