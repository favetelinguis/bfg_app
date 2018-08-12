# Load another ".iex.exs" file
# import_file "~/.iex.exs"

# Import some module from lib that may not yet have been defined
# import_if_available MyApp.Mod

# Print something before the shell starts
# IO.puts "hello world"

alias BfgEngine.Betfairex.Rest.Connection
alias BfgEngine.Betfairex.{Rest, Filters}

usr = Application.get_env(:bfg_engine, :betfair_user)
pwd = Application.get_env(:bfg_engine, :betfair_password)
key = Application.get_env(:bfg_engine, :betfair_app_key)

login = fn -> Connection.start_link(usr, pwd, key) end
# {:ok, pid} = Connection.start_link(usr, pwd, "aa")
