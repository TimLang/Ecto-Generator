defmodule Model_Generator do

  # Open a mariaex connection
  def connect(hostname, database, username, password) do
    Mariaex.Connection.start_link(hostname: hostname, database: database, username: username, password: password)
  end

  # Kill the connection
  def terminate(p) do
    Mariaex.Connection.stop(p)
  end

  # Get all the tables in a database
  def get_tables(connection, db) do
    {:ok, result} = Mariaex.Connection.query(connection, "SELECT table_name FROM information_schema.tables WHERE table_schema=?;", [db])
    result.rows
  end

  # Perform query to get schema and generate results
  def generate(connection, db, table) do
    {:ok, result} = Mariaex.Connection.query(connection, "SELECT column_name, data_type, CASE WHEN `COLUMN_KEY` = 'PRI' THEN '1' ELSE NULL END AS primary_key FROM information_schema.columns WHERE table_name=? AND table_schema=?;", [table, db])

    write_model(db, table, result.rows)
  end

  # Loop through the rows and output to a file
  defp write_model(db, table, rows) do

		# Downcased table and db so we can interpolate
    lc_table = String.downcase(table)
    lc_db = String.downcase(db)

		# Map the rows to their associated types
		mapped_rows = Enum.map rows, fn {name, type, is_primary} ->
      { name, get_type(type), is_primary }
    end

    primary_key = Enum.find mapped_rows, fn(row) ->
      elem(row, 2) == "1"
    end

		# Render the schema template
		output = EEx.eval_file("templates/schema.eex", [db: db, table: table, primary_key: primary_key, columns: mapped_rows, lc_table: lc_table, lc_db: lc_db])

    # Make the directory if it doesn't exist
    File.mkdir_p("./output/#{db}/")

    # Downcased table and db so we can interpolate
    lc_table = String.downcase(table)
    lc_db = String.downcase(db)

    # Create the filename
    filename = "./output/#{db}/#{lc_db}_#{lc_table}.ex"

    # rm the file first
    File.rm filename

    # Fencepost plant, filenaming is 'dbname_tablename.ex'
    {:ok, file} = File.open(filename, [:append])

    # Write the template to the file
    IO.binwrite file, output

    # Close file reference
    File.close(file)

    IO.puts "Model created: #{filename}"
  end

  # Get the type of a row
  def get_type(row) do

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
        ":date"
      type when type in ["datetime", "timestamp"] ->
        ":datetime"
      type when type in ["time"] ->
        ":time"
      type when type in ["blob"] ->
        ":binary"
    end
  end
end
