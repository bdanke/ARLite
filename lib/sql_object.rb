require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  # sets the table_name
  def self.set_table_name(table_name = nil)
    unless table_name.nil?
      @table_name = table_name
    else
      @table_name = self.class.to_s.underscore + "s"
    end
  end

  # gets the table_name
  def self.table_name
    @table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    results.map { |result| self.new(result) }
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    return nil if results.empty?
    self.new(results[0])
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
    cols = []

    attr_names = self.class.attributes
    attr_names.each do |attrib|
      cols << attrib.to_s
    end

    col_names = "(" + col.join(", ") + ")"
    qs = ["?"] * attrs.length
    q_str = qs.join(", ")

    values = attribute_values

    DBConnection.execute(<<-SQL, *values)
      INSERT INTO #{self.class.table_name} #{col_names}
      VALUES #{q_str}
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    set_str = []
    attr_names = self.class.attributes
    attr_names.each do |name|
      set_str << "#{name} = ?"
    end
    values = attribute_values

    DBConnection.execute(<<-SQL, *values)
      UPDATE #{self.class.table_name}
      SET #{set_str.join(", ")}
      WHERE id = #{self.id}
    SQL
  end

  # call either create or update depending if id is nil.
  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  # helper method to return values of the attributes.
  def attribute_values
    attr_names = self.class.attributes
    attr_names.map { |name| self.send(name) }
  end
end
