# Import all the modules
require Application

# Get the args
args = CLI.get_args()

# If there aren't args or there was an error getting them
# exit status 1
if (!args) do
  System.halt 1
end

# Start the connection
{:ok, connection} = Model_Generator.connect(args[:hostname], args[:database], args[:username], args[:password])

# If they provided a table get its structure and generate a model based on it
if args[:table] do
  Model_Generator.generate(connection, args[:database], args[:table])
else
  tables = Model_Generator.get_tables(connection, args[:database])
  Enum.each tables, fn(table) ->
    Model_Generator.generate(connection, args[:database], elem(table, 0))
  end
end

# Always kill the connection when we're done
Model_Generator.terminate(connection)
