defmodule ModelGenerator do

  def start(adapter_name, %Config{} = config, project_name \\ "Entry") do
    {:ok, pid} = call(adapter_name, :get_pid, [config]) 
    tables = call(adapter_name, :get_tables, [pid])

    Enum.each tables, fn(table) ->
      generate(adapter_name, pid, config, hd(table), project_name)
    end
  end


  # Perform query to get schema and generate results
  defp generate(adapter_name, pid, %Config{} = config, table, project_name) do
    db = config.database
    rows = call(adapter_name, :get_table_columns_meta, [pid, db, table])

    unless table == "schema_migrations" do
      write_model(adapter_name, db, table, rows, project_name)
    end
  end
    
  # Loop through the rows and output to a file
  defp write_model(adapter_name, db, table, rows, project_name) do

		# Downcased table and db so we can interpolate
    lc_table = String.downcase(table)
    lc_db = String.downcase(db)

		# Map the rows to their associated types
    rows = Enum.map(rows, fn(list) ->  List.to_tuple(list) end)
		mapped_rows = Enum.map rows, fn {name, type, is_primary} ->
      { name, call(adapter_name, :mapping_column_type, [type]), is_primary }
    end

    primary_key = Enum.find mapped_rows, fn(row) ->
      elem(row, 2) == "1"
    end

		# Render the schema template
		output = EEx.eval_file("templates/schema.eex", [db: db, project_name: project_name, table: table, primary_key: primary_key, columns: mapped_rows, lc_table: lc_table, lc_db: lc_db])

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

  defp call(class_name, method, args \\ []) do
    call_method = unless is_atom(method) do
                    String.to_atom(method)
                  else              
                    method
                  end
    apply(Module.concat(["#{String.capitalize(class_name)}Processor"]), call_method, args)
  end

end
