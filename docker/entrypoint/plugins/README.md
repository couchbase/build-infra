# Developing Universal Entrypoint Plugins

## Overview

Plugins are shell-script snippets saved in this repository under
`docker/entrypoint/plugins`. A particular container instance may run any
of them, in any order, depending on the value of `CB_ENTRYPOINT_PLUGINS`
at run time.

Some plugins are "final" plugins, meaning that they do not return
control back to the universal entrypoint script when they run. This will
usually be because it launches a long-running process such as a Jenkins
agent, etc. Such plugins will document themselves as "final".

## Plugin requirements

Plugin scripts are not executed, but rather are sourced by the universal
entrypoint script. As such, they do not need (and should not have) a
`#!/bin/bash` shebang line, nor is it necessary for them to be
executable. They should, however, have a `.sh` extension - this is
primarily to ensure proper code highlighting in IDEs.

It is NOT expected that plugins will do any kind of software
installation or similar activities. This isn't meant to serve as
something like cloud-init. The goal is to allow the same toolchain to be
utilized in several different environment.

It is up to the person deploying an agent container to request plugins
that match the software already installed in the image. Plugins should
document their assumptions and dependencies in header comments, and use
functions like `chk_cmd`, `chk_file`, and `chk_env` to assert that their
assumptions are met.

## Writing and testing plugins

To create a new plugin, add it as a new shell script under the
`docker/entrypoint/plugins` directory.

To test your plugin, include the entire `docker/entrypoint/*` hierarchy
in your image, including `plugins/`, `healthchecks/`, and
`universal-entrypoint.sh`. Then launch the container, setting the
environment variable `CB_DEBUG_LOCAL_PLUGINS` to any non-empty value and
overriding the entrypoint script with the path to
`universal-entrypoint.sh`.

For example, while testing, add the following to your Dockerfile:

    COPY entrypoint /entrypoint-test

and then run a container with something like:

    docker run --entrypoint /entrypoint-test/universal-entrypoint.sh \
        -e CB_DEBUG_LOCAL_PLUGINS=y ....

When you are done testing, remove that `COPY` from your Dockerfile.

## Publishing updating plugins

When you are satisified with your changes, you can run the script
`./publish.sh` to sync `plugins`, `healthchecks`, and
`universal-entrypoint.sh` to the `cb-entry` bucket on S3. This will
overwrite any files already there, and delete any files from S3 that are
missing from the `plugins` or `healthchecks` directories.

## Utility functions available to universal entrypoint plugins

### Reporting status

  * `status <message>` - outputs "message" with leading dashes.
  * `header <message>` - outputs "message" with surrounding lines of
    `::::::::`.

### Asserting requirements

  * `chk_set VAR1 VAR2 ...` - aborts container launch with an
    appropriate message if any of the specified environment variables
    are not set.
  * `chk_file /path/to/file1 /path/of/file2 ...` - aborts container
    launch with an appropriate message if any of the specified files do
    not exist.
  * `chk_cmd cmd1 cmd2 ...` - aborts container launch with an
    appropriate message if any of the specified commands are not on the
    `$PATH`.
  * `abort <message>` - aborts container launch with the specified
    message.

### Calling other plugins

  * `invoke_plugin <plugin/name>` - retrieves and invokes the specified
    plugin. Control will be returned to the invoking plugin unless the
    invoked plugin is a *final* plugin. `status` messages output by the
    invoked plugin will be more deeply indented than those for the
    calling plugin, allowing the nesting behaviour to be visible in
    `docker logs`.

  * `install_healthcheck <checker>` - retrieves the named healthcheck
    script and places it at `/tmp/healthcheck.sh`. As documented in [the
    main README](../README.md), it is up to the container launch
    environment to ensure that this script is in fact declared to be the
    healthcheck script for the running container.

### Miscellaneous

  * `add_group <group>` - adds a Unix group *to the running entrypoint
    process*. This has a special function because it is very tricky to
    do; it requires re-invoking the entrypoint script from the top,
    while avoiding re-invoking all the previously-run plugins. This
    function does NOT add a Unix group via `groupadd`; the Unix group
    must already exist. If you call this function, it must be the final
    step of your plugin; control will not be returned to your plugin,
    and your plugin will not be re-invoked.
