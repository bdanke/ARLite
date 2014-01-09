class MassObject
  # takes a list of attributes.
  # creates getters and setters.
  # adds attributes to whitelist.
  def self.my_attr_accessible(*attributes)
    my_attr_accessor(*attributes)
    @attributes = []
    @attributes += attributes
  end

  def self.my_attr_accessor(*attributes)
    attributes.each do |attribute|
      define_method("#{attribute}") do
        instance_variable_get("@#{attribute}".to_sym)
      end

      define_method("#{attribute}=") do |value|
        instance_variable_set("@#{attribute}", value)
      end
    end
  end

  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes ||= []
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    objs = []
    results.each do |result|
      objs << new(result)
    end
    objs
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})
    params.each do |attr_name, value|
      attrs = self.class.attributes
      if attrs.include?(attr_name) || attrs.include?(attr_name.to_sym)
        if attr_name.is_a?(Symbol)
          self.send(attr_name.to_s+"=", value)
        else
          self.send(attr_name+"=", value)
        end
      else
        raise "mass assignment to unregistered #{attr_name}"
      end
    end
  end
end