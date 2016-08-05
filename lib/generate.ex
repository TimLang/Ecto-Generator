defmodule Mix.Tasks.Generate do
	use Mix.Task

	def run(_) do
		# Import all the modules
    Mix.Task.run "app.start", []

		# Get the args
		args = CLI.get_args()

		# If there aren't args or there was an error getting them
		# exit status 1
		if (!args) do
			System.halt 1
		end

    inited_config = %Config{}
    config = Map.merge(inited_config, args)

    ModelGenerator.start("postgres", config, args[:project])
    
	end
end
