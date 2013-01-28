# This is the mechanism by which droom's preferences system is bolted onto the host app's user class.
# 
module Droom
  # LazyHash is a recursive hash descendant that accepts keys in the form `key:subkey:subsubkey` and populates 
  # nested hashes accordingly.
  #
  # In droom this mechanism is used to manage the default values that sit behind user preferences. The motive
  # is to match the `User#pref(key)` interface, with concatenated keys designating namespaced values:
  #
  #   LazyHash.set("key:subkey:otherkey:something", "hippopotamus")
  #     => {:key => {:subkey => {:otherkey => {:something => "hippopotamus"}}}}
  #
  #   LazyHash.get("key:subkey:otherkey") => {:something => "hippopotamus"}
  #   LazyHash.get("key:subkey:otherkey:something") => "hippopotamus"
  #
  # An unset value will always return nil. A set value may be false. You may want to test for the difference.
  #
  # NB. keys are always symbolized.
  #
  class LazyHash < Hash
    
    def initialize(*args)
      super
      args.extract_options!.each_pair do |k,v|
        self[k] = v.is_a?(Hash) ? Droom::LazyHash.new(v) : v
      end
    end

    # *get* will return the value in the named bucket. The bucket is designated
    # by a key that can either be simple or the colon:separated path to a nested hash. 
    #
    def get(path)
      if subkeys.any?
        if self[key].is_a?(Droom::LazyHash)
          self[key].get(subkeys)
        else
          nil
        end
      elsif self.key?(key)
        self[key]
      else
        nil
      end
    end
    
    # *set* will set the value at the named bucket. Note that you should only ever do this from an 
    # initializer or some other thread-global event that can be relied upon always to run. Never call
    # LazyHash#set at runtime unless what you want is a local, non-thread-global nested hash construction.
    #
    def set(path, value)
      key, subkeys = split_path(path)
      if subkeys.any?
        self[key] ||= Droom::LazyHash.new({})
        self[key].set(subkeys, value)
      else
        self[key].set(value)
      end
    end
    
    #
    def split_path(key)
      keys = key.is_a?(Array) ? key : key.to_s.split(':')
      keys.any? ? [keys.shift.to_sym, keys] : [nil, []]
    end

  end
end