require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

require 'debugger'

class AssocParams
  attr_reader :other_class, :other_table

  def other_class
    @other_class_name.constantize
  end

  def other_table
    @other_class_name.underscore + "s"
  end
end

class BelongsToAssocParams < AssocParams
  attr_reader :name, :other_class_name, :foreign_key, :primary_key

  def initialize(name, params)
    @name = name
    if params[:class_name].nil?
      @other_class_name = name.to_s.camelize
    end
    if params[:foreign_key].nil?
      @foreign_key = name.to_s + "_id"
    end
    if params[:primary_key].nil?
      @primary_key = "id"
    end
    if params[:class_name]
      @other_class_name = params[:class_name]
    end
    if params[:foreign_key]
      @foreign_key = params[:foreign_key]
    end
    if params[:primary_key]
      @primary_key = params[:primary_key]
    end
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_reader :name, :other_class_name, :foreign_key, :primary_key

  def initialize(name, params, self_class)
    @name = name
    if params[:class_name].nil?
      @other_class_name = name.to_s.singularize.camelize
    end
    if params[:foreign_key].nil?
      @foreign_key = self_class.to_s.underscore + "_id"
    end
    if params[:primary_key].nil?
      @primary_key = "id"
    end
    if params[:class_name]
      @other_class_name = params[:class_name]
    end
    if params[:foreign_key]
      @foreign_key = params[:foreign_key]
    end
    if params[:primary_key]
      @primary_key = params[:primary_key]
    end
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps
    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.foreign_key))
        SELECT *
        FROM #{aps.other_table}
        WHERE #{aps.other_table}.#{aps.primary_key} = ?
      SQL
      return nil if results.empty?
      aps.other_class.new(results[0])
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self.class)
    assoc_params[name] = aps
    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.primary_key))
        SELECT *
        FROM #{aps.other_table}
        WHERE #{aps.other_table}.#{aps.foreign_key} = ?
      SQL
      return nil if results.empty?
      results.map { |result| aps.other_class.new(result) }
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(self.class.assoc_params[assoc1].foreign_key))
        SELECT a2.*
        FROM #{self.class.assoc_params[assoc1].other_table} a1
        JOIN #{self.class.assoc_params[assoc1].other_class.assoc_params[assoc2].other_table} a2 ON a1.#{self.class.assoc_params[assoc1].other_class.assoc_params[assoc2].foreign_key} = a2.#{self.class.assoc_params[assoc1].other_class.assoc_params[name].primary_key}
        WHERE a1.#{self.class.assoc_params[assoc1].other_class.assoc_params[assoc2].primary_key} = ?
      SQL
      return nil if results.empty?
      self.class.assoc_params[assoc1].other_class.assoc_params[assoc2].other_class.new(results[0])
    end
  end
end
