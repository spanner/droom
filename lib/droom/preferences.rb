# This is the mechanism by which droom's preferences system is bolted onto the host app's user class.
# 
module Droom
  # This is a recursive hash descendant that accepts keys in the form `key:subkey:subsubkey` and populates 
  # nested hashes accordingly. It allows both the standard []= and a more convenient method-call interface.
  #
  # The values we set are always stored as Droom::Preference objects, and an existing preference will always
  # be updated rather than replaced.
  #
  # Call new with an existing hash to populate the PreferencesHash with defaults. Default values are not 
  # preference objects and will be replaced if a value is set.
  #
  # #todo: indifferent access.
  #
  class PreferencesHash < Hash
    
    # PreferencesHash.new() takes as (optional) argument a hash that will be treated as defaults.
    #
    def initialize(*args)
      super
      args.extract_options!.each_pair do |k,v|
        self[k] = v.is_a?(Hash) ? Droom::PreferencesHash.new(v) : v
      end
    end

    def inspect
      "PreferencesHash: #{super}"
    end

    # *get* will return the value in the named bucket. The bucket is designated
    # by a key that can either be simple or the colon:separated path to a nested hash. 
    # If there happens to be a preference held in that bucket, we return its value. 
    # If not, we return whatever is there (which will usually be a simple default).
    #
    def get(path)
      key, subkeys = split_path(path)
      p "!!! get #{path}"
      p "key: #{key}"
      p "subkeys: #{subkeys.inspect}"
      if subkeys.any?
        if self[key].is_a?(Droom::PreferencesHash)
          self[key].get(subkeys)
        else
          nil
        end
      else
        if self[key].is_a? Droom::Preference
          self[key].value
        else
          self[key]
        end
      end
    end
    
    # *set* will place or update a Preference object in the named bucket.
    #
    def set(path, value)
      key, subkeys = split_path(path)
      if subkeys.any?
        self[key] ||= Droom::PreferencesHash.new({})
        self[key].set(subkeys, value)
      else
        if self[key].is_a? Droom::Preference
          self[key].set(value)
        else
          #todo where's the user, eh?
          self[key] = Droom::Preference.create(:key => key, :value => value)
        end
      end
    end
    
    # has_path? returns true if there is anything (either default or preference) in the named bucket.
    #
    def has_path?(path)
      p "has_path? #{path}}"
      key, subkeys = split_path(path)
      if subkeys.any?
        self[key].has_path?(subkeys)
      else
        self.has_key?(key.to_sym)
      end
    end
    
    # Returns true if there is a preference object in the named bucket.
    #
    def has_preference?(path)
      key, subkeys = split_path(path)
      if subkeys.any?
        self[key].has_preference?(subkeys)
      else
        self[key].is_a? Droom::Preference
      end
    end

    #
    #
    def split_path(key)
      keys = key.is_a?(Array) ? key : key.to_s.split(':')
      keys.any? ? [keys.shift.to_sym, keys] : [nil, []]
    end
    
    # nb. this will support both prefs.something.something and prefs.something:something, which is a bit
    # unnecessary but there you go.
    #
    def method_missing(method_name, *args, &blk)
      p "method_missing `#{method_name}`"
      return self.get(method_name, &blk) if has_path?(method_name)
      match = method_name.to_s.match(/(.*?)([?=]?)$/)
      case match[2]
      when "="
        self.set(match[1], args.first)
      when "?"
        !!self[match[1]]
      else
        default(method_name, *args, &blk)
      end
    end
  end
  
  
  module Preferences
  
    def self.included(base)
      base.extend PreferenceClassMethods
    end

    module PreferenceClassMethods
      def has_preferences?
        false
      end
      
      # All you need is a has_preferences call:
      #
      #   class User < ActiveRecord::Base
      #     has_preferences
      #   end
      #
      # This will bring in a preferences association and all the instance methods involved in
      # getting, setting and defaulting those values. The preferences themselves are held in a
      # model class as simple key => value pairs, where key is usually a compound string like
      # key:subkey:subkey.
      #
      def has_preferences( options={} )
        return if has_preferences?
        has_many :preferences, :class_name => "Droom::Preference", :foreign_key => "created_by_id"
        
        class_eval {
          extend Droom::Preferences::PreferringClassMethods
          include Droom::Preferences::PreferringInstanceMethods
        }
      end
    end

    module PreferringClassMethods
      # The has_preferences? method is used to prevent multiple calls to has_folder, but might possibly be useful elsewhere.
      def has_preferences?
        true
      end
    end
  
    module PreferringInstanceMethods
      #
      # Returns a PreferenceHash object, which allows us to make deep calls like this:
      #
      #   if object.prefs.email.digest? ... end
      #   object.prefs.likes.oranges = true
      #   object.prefs.patience = "endless"
      #
      #
      def prefs
        unless @prefs
          @prefs = Droom::PreferencesHash.new(Droom.user_defaults)
          preferences.each do |p|
            @prefs.set(p.key, p.value)
          end
        end
        @prefs
      end
      
      
      def preference(key)
        if pref = preferences.find_by_key(key)
          pref.value
        else
          Droom.user_default(key)
        end
      end
      
      def get_preference(key)
        preferences.find_or_create_by_key(key)
      end

      def set_preference(key, value)
        preference(key).set(value)
      end

    end
  end

end