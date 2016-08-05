
defmodule MysqlProcessor do
  
  def get_pid(%Config{} = config) do
    Mariaex.Connection.start_link(Map.to_list(Map.from_struct(config)))
  end

  def get_tables(pid, db) do
    {:ok, result} = Mariaex.Connection.query(pid, "SELECT table_name FROM information_schema.tables WHERE table_schema=?;", [db])
    result.rows
  end
   # Get the type of a row
  def mapping_column_type(row) do

    # Match the type and return the atom representing it
    case row do
      type when type in ["int", "bigint", "mediumint", "smallint", "tinyint"] ->
        ":integer"
      type when type in ["varchar", "text", "char", "year", "mediumtext", "longtext", "tinytext", "enum"] ->
        ":string"
      type when type in ["decimal", "float", "double"] ->
        ":float"
      type when type in ["bit"] ->
        ":boolean"
      type when type in ["date"] ->
        "Ecto.Date"
      type when type in ["datetime", "timestamp"] ->
        "Ecto.DateTime"
      type when type in ["time"] ->
        ":time"
      type when type in ["blob"] ->
        ":binary"
      _ ->
        ":string"
    end
  end

  # Kill the connection
  def terminate(p) do
    Mariaex.Connection.stop(p)
  end

end
