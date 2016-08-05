# Handle CLI input
defmodule CLI do
  def get_args do
    case length(System.argv()) do
      # Check if we have args
      arg_count when arg_count >= 1 ->

        # Paired options, unpaired, error
        { parsedOptions, _, _ } = OptionParser.parse(System.argv)

        # Turn the list into a map of key value pairs and return
        parsedOptions = Enum.into(parsedOptions, %{})

        # Check for shard and database
        if (!parsedOptions[:hostname] || !parsedOptions[:database]) do
          IO.puts "--hostname and --database are required"
          false
        else
          # Return parsed options
          parsedOptions
        end

      arg_count when arg_count === 0 ->
        IO.puts "Usage: mix generate --hostname <hostname> --database <database> --table <table> --username <username> --password <password> --adapter <postgres>"
        false
      # Fallback
      _ ->
        IO.puts "Usage: mix generate --hostname <hostname> --database <database> --table <table> --username <username> --password <password> --adapter <postgres>"
        false
    end
  end
end
