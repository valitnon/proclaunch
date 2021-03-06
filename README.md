Proclaunch is a super simple pure-perl user space process manager. It starts your processes and keeps them running. It's comparable to [runit][], except it manages processes that know how to daemonize themselves. It's also only a few hundred lines of simple perl with minimal dependencies. 

### Installation

    $ git clone git://github.com/peterkeen/proclaunch.git
    $ cd proclaunch
    $ perl Build.PL
    $ ./Build install

### Usage

    $ proclaunch [options] [state directory] [profile directory]

When executed, proclaunch will daemonize itself and write it's pid file to `$state_directory/proclaunch.pid`.

The profile directory should contain a series of directories, each of which describes a process to be managed via a set of specially named files:    

* `pid_file`
    contains the path to the file where run will place it's pid

* `run`
    is an executable script that will daemonize itself and write it's pid to the path in pid_file

* `restart`
    is an optional empty file who's presence tells proclaunch to restart `run` if it dies.

* `stop_signal`
    is an optional file that should contain a signal name that proclaunch will use to terminate the process. Default is SIGTERM.

* `reload`
    is an optional file who's presence indicates that proclaunch should send the contained signal and assume that the process will either continue running or manage it's own lifecycle. An empty file will use the default SIGHUP.
    
* `user`
    is an optional file containing the user name that should execute `run`. Only effective if proclaunch has been run as root.

Options can include:

* `--foreground -F`
    run in the foreground. Do not daemonize.

* `--debug -D`
    include DEBUG output in proclaunch's log

* `--log-level=[LOG LEVEL]`
    instead of just debug, you can specify FATAL, WARN, INFO, or DEBUG as the maximum level of logging information you want. Default is INFO.
    
### Behavior

Initially, proclaunch will launch all profiles contained in the profile directory. When a profile exits and the `restart` file exists, the profile will be restarted. Additionally, proclaunch will scan every second to see if either an individual profile directory has changed, been added, or disappeared. Added profiles will be started, removed profiles will be stopped with SIGTERM or another signal as indicated in the `restart` file, and changed profiles will be restarted or reloaded. Changes are determined by comparing file stats of the above set of files, not the directory as a whole.

### Starting proclaunch

Proclaunch daemonizes itself by default, so the easiest thing to do is add a line to crontab:

    * * * * * /usr/local/bin/proclaunch /var/run/proclaunch /path/to/your/profiles/directory

Proclaunch is idempotent, meaning if it's already running it'll silently exit. This cron entry ensures that it will be restarted if it falls over for any reason.

### Stopping proclaunch

To stop proclaunch without stopping profiles, send it SIGINT or SIGTERM. If you want to stop all of the profiles as well, send it SIGHUP. It will wait around for all the profiles to die, so if you have a misbehaving profile you can send it SIGHUP again and proclaunch will die immediately. Your misbehaving profile will continue to misbehave.

### Contributing 

If you have bug reports, please use the [Github issue tracker][issues]. If you have something to contribute, fork proclaunch and send me a pull request :)

[runit]:           http://smarden.org/runit/
[issues]:          http://github.com/peterkeen/proclaunch/issues

