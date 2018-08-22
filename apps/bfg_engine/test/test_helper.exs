ExUnit.start()
Application.ensure_all_started(:bypass)

# Load files from resources directory
{:ok, files} = File.ls("./test/resources")
Enum.each files, fn(file) ->
  Code.require_file "resources/#{file}", __DIR__
end
###
