Ecto Generator
==============
Takes an existing MySQL database and outputs ecto models for it.

Usage:
```shell
mix run generate.exs --hostname <hostname> --database <database> --table <table>
```

Models will be places in the `output/<database_name>` folder
