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
    {:ok, result} = Mariaex.Connection.query(connection, "SELECT column_name, data_type FROM information_schema.columns WHERE table_name=?;", [table])
    write_model(db, table, result.rows)
  end

  # Loop through the rows and output to a file
  defp write_model(db, table, rows) do

    # Make the directory if it doesn't exist
    File.mkdir_p("./output/#{db}/")

    # Get the filename
    filename = "./output/#{db}/" <> String.downcase(db) <> "_" <> String.downcase(table) <> ".ex"

    # rm the file first
    File.rm filename

    # Fencepost plant, filenaming is 'dbname_tablename.ex'
    {:ok, file} = File.open(filename, [:append])

    # Write the generic first two lines
    IO.binwrite(file, "defmodule #{db}.#{table} do\n")
    IO.binwrite(file, "  use Ecto.Schema\n\n")
    IO.binwrite(file, "  schema \"" <> String.downcase(table) <> "\" do\n")

    # Loop through each row, outputting its name and type
    Enum.each rows, fn(row) ->
      # Elixir atoms don't have a "raw output" function so we need to
      # fake it
      fieldName = ":" <> elem(row, 0)
      IO.binwrite(file, "    field #{fieldName}, " <> get_type(row) <> "\n")
    end

    # Write the generic last two lines
    IO.binwrite(file, "  end\nend")

    # Close file reference
    File.close(file)
  end

  # Get the type of a row
  defp get_type(row) do

    # Match the type and return the atom representing it
    case row do
      {_, type} when type in ["int", "bigint", "mediumint", "smallint"] ->
        ":integer"
      {_, type} when type in ["varchar", "text", "char", "year", "mediumtext", "longtext", "tinytext"] ->
        ":string"
      {_, type} when type in ["decimal", "float", "double"] ->
        ":float"
      {_, type} when type in ["tinyint", "bit"] ->
        ":boolean"
      {_, type} when type in ["date"] ->
        ":date"
      {_, type} when type in ["datetime"] ->
        ":datetime"
      {_, type} when type in ["timestamp", "time"] ->
        ":time"
      {_, type} when type in ["blob"] ->
        ":binary"
      {_, type} when type in ["enum"] ->
        "{:array, :string}"
    end
  end
end
