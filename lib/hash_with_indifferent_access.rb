# Allow accessing string keys with symbols.
# hash = { "a" => { "b" => 1 } }
# hash[:a] # => nil
# hash = hash.to_h_with_indifferent_access
# hash[:a][:b] # => 1
class HashWithIndifferentAccess < Hash
  def [](key)
    return super(key) unless key.is_a? Symbol

    super(key) || super(key.to_s)
  end
end

Hash.class_eval do
  def to_h_with_indifferent_access
    res = transform_values do |v|
      if v.is_a? Hash
        v.to_h_with_indifferent_access
      else
        v
      end
    end

    HashWithIndifferentAccess[res]
  end
end
