# Developing Universal Entrypoint Plugins

## Plugin scripts

Plugins are shell-script snippets saved in this repository under
`docker/entrypoint/plugins`. A particular container instance may run any
of them, in any order, depending on the value of `CB_ENTRYPOINT_PLUGINS`
at run time.

Some plugins are "final" plugins, meaning that they do not return
control back to the universal entrypoint script when they run. This will
usually be because it launches a long-running process such as a Jenkins
agent, etc. Such plugins will document themselves as "final".

## Writing plugin scripts

Plugin scripts are not executed, but rather are sourced by the universal
entrypoint script. As such, they do not need (and should not have) a
`#!/bin/bash` shebang line, nor is it necessary for them to be
executable. They should, however, have a `.sh` extension - this is
primarily to ensure proper code highlighting in IDEs.

There are a series of shell functions which plugins may use for
producing output; checking for environment variables, files, etc;
invoking another plugin; installing a healthcheck script; and adding a
unix group to the entrypoint process. See the plugin
`universal/entrypoint.sh` for details.

It is NOT expected that plugins will do any kind of software
installation or similar activities. This isn't meant to serve as
something like cloud-init. It is up to the person deploying an agent
container to request plugins that match the software already installed
in the image. Plugins should document their assumptions and dependencies
in header comments, and use functions like `chk_cmd`, `chk_file`, and
`chk_env` to assert that their assumptions are met.

## Utility functions available to universal entrypoint plugins
