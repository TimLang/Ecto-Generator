
defmodule PostgresProcessor do
  
  def get_pid(%Config{} = config) do
    Postgrex.start_link(Map.to_list(Map.from_struct(config)))
  end

  def get_tables(pid, _ \\ nil) do
    {:ok, result} = Postgrex.query(pid, "select table_name from information_schema.tables where table_schema='public'", [])
    result.rows
  end

  def get_table_columns_meta(pid, db, table) do
    {:ok, result} = Postgrex.query(pid, "SELECT t.column_name, t.data_type, CASE WHEN us.column_name = t.column_name THEN '1' ELSE NULL END AS primary_key FROM information_schema.columns t left join information_schema.constraint_column_usage us on us.table_catalog = t.table_catalog and us.table_name = t.table_name WHERE t.table_schema = 'public' AND t.table_name = $1 and t.table_catalog = $2", [table, db])
    result.rows
  end

  def mapping_column_type(row) do
    case row do
      type when type in ["integer", "smallint", "bigint"] ->
        ":integer"
      type when type in ["character varying", "text"] ->
        ":string"
      type when type in ["boolean"] ->
        ":boolean"
      type when type in ["time"] ->
        ":time"
      type when type in ["timestamp", "timestamp without time zone"] ->
        "Ecto.DateTime"
        #Array? how to do?
      type when type in ["ARRAY"] ->
        "{:array, :string}"
      _ ->
        IO.puts "no mapping: #{row}"
        ":unknown"
    end
  end

end
