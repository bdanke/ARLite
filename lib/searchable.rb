require_relative './db_connection'

module Searchable
  def where(params)
    values = params.values
    where_str = params.keys.map { |key| "#{key} = ?" }
    results = DBConnection.execute(<<-SQL, *values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_str.join(" AND ")}
    SQL
    return nil if results.empty?
    results.map { |result| self.new(result) }
  end
end