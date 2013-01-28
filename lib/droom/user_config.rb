# This is a recursive hash that accepst keys in the form `key:subkey:subsubkey` and
# populates nested hash objects accordingly. It allows both the standard []= and a more
# convenient method-call notation.
#
# 
#
# Call new with an existing hash to populate the LazyHash with defaults.

module Droom

  class PreferencesHash < Hash
    def get(path)
      key, subkeys = split_path(path)
      if subkeys.any?
        self[key.to_sym].get(subkeys)
      else
        if self[key].is_a? Droom::Preference
          self[key].value
        else
          self[key]
        end
      end
    end
    
    def set(path, value)
      key, subkeys = split_path(path)
      if subkeys.any?
        self[key] ||= LazyHash.new({})
        self[key].set(subkeys, value)
      else
        if self[key].is_a? Droom::Preference
          self[key].set(value)
        else
          self[key] = value
        end
      end
    end
  
    def has_path?(path)
      key, subkeys = split_path(path)
      if subkeys.any?
        self[key.to_sym].has_path?(subkeys)
      else
        self.has_key?(key.to_sym)
      end
    end

    def split_path(key)
      keys = path.is_a?(Array) ? path : path.to_s.split(':')
      [keys.shift, keys]
    end
  
    def method_missing(method_name, *args, &blk)
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

end