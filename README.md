# Comanche
A pocket-sized Ruby HTTP server.

### Disclaimer

Comanche was made just for fun, and is **NOT** production-ready. You've been warned!

Comanche as of today isn't built as a Gem, which means the installation process isn't automatic. This will become available in future versions.

### Usage

``` shell
./comanche [flags] [port]
```

* Flags
  - `-h`, `--help`: Show the help.
  - `-v`, `--version`: Show the version.
  - `-d`, `--daemon`: Start the server as a daemon. The output will be redirected to the `comanche.log` file.
  - `-k`, `--kill`: Stop a daemonized instance of Comanche.
  - `-r`, `--restart`: Stops any running instance of Comanche and launches a new one. (Can be daemonized)
* Port: Optional, can override the port specified in the config file.

### Configuration

Comanche uses a YAML file for its configuration. A template will be created under `config/comanche.conf.yml` the first time it starts. Only the options present in the template file are available at the moment.

* Server
  - `port`: Port to listen to, can be overriden temporarily on the command line.
  - `verbose`: Output more information to the terminal or log file. Ignored at the moment.
  - `timeout`: Time in seconds after which a single request should stop being processed.
* Website
  - `root`: Path, relative or absolute, to the root of the website. The server will not be allowed to go higher in the hierarchy.
  - `not_found`: Path (relative to `root`) to your custom 404 error page.
* Mods
  - `mod_dir`: Enables the directory listing mod. You can customize the view by editing the `templates/dir.html.erb` file.
