# Dynamic Universal build agent ENTRYPOINT script

`universal-entrypoint.sh` is a script intended to be used as the
entrypoint for all Couchbase build-agent containers. It should generally
be included in a Docker image via the following Dockerfile directives:

    ADD --chmod=0755 https://cb-entry.s3.us-west-2.amazonaws.com/universal-entrypoint.sh /universal_entrypoint.sh
    ENTRYPOINT ["/universal_entrypoint.sh"]
    CMD []

It intentionally does minimal processing itself. Instead, it will
downloand and invoke a series of plugin scripts from S3 at container
startup. This allows the startup behaviour to be dynamic depending on
the environment the container is launched in, and to be updated without
needing to rebuild the container image. Indeed, much of the
functionality of the universal entrypoint script itself is implemented
in plugins (under the `universal` directory), so that even this
top-level behaviour can be dynamic and we can deploy bug fixes.

## Container invariants

The container image must be configured such that the entrypoint script
is run by a non-root user, usually `couchbase`. Some plugins will expect
that the user has password-less `sudo` privileges.

The container image must have at least `bash` and `curl` installed.
Individual plugins will have additional requirements.

The container image must include `universal-entrypoint.sh`, and have its
`ENTRYPOINT` set to the full path to that script. It should not have a
`CMD` directive, although certain plugins may be able to process
command-line arguments.

## Configuring universal entrypoint behaviour

The following environment variables may be set to control the universal
entrypoint behaviour. These variables should be set by the system
launching the container, such as a Docker stack file. They should
generally NOT be baked into the container image itself, as the intent is
for the startup behaviour to be configured at container launch time.

* `CB_ENTRYPOINT_PLUGINS`: A space-separated list of plugin scripts to
  download and invoke, in order.

* `CB_ENTRYPOINT_BASE`: A base URL to load plugins from. This URL should
  have a `plugins` subdirectory, and optionally a `healthchecks`
  subdirectory. Defaults to https://cb-entry.s3.us-west-2.amazonaws.com
  . This variable should NOT have a trailing `/` character.

* `CB_DEBUG_ENTRYPOINT`: If set, enable shell tracing (`set -x`).

* `CB_DEBUG_LOCAL_PLUGINS`: For use when developing new plugins; see
  [`plugins/README.md`](plugins/README.md).


## Healthcheck scripts

Additionally, some plugins may wish to install a specific healthcheck
script. The universal entrypoint plugin provides an
`install_healthcheck` function for this, which will download a
healthcheck script from `${CB_ENTRYPOINT_BASE}/healthchecks`.

However, an ENTRYPOINT script cannot directly set the healthcheck
command for the container. Instead we require the container's
healthcheck command to be defined as exactly `["CMD",
"/tmp/healthcheck.sh"]`. The `install_healthcheck` function will
download the required healthcheck script to this location.

The healthcheck command can be set at runtime using the `healthcheck`
option in a Docker stack file or the `--health-cmd` option to `docker
run`. (It can also be baked into to the image using the HEALTHCHECK
instruction in the Dockerfile, but doing this goes against the dynamic
nature of the Universal Entrypoint script and so is discouragd.) An
example is shown below.

# A complete Docker Swarm example

    services:
      universal-demo:
        image: couchbasebuild/universal-demo:20250811
        environment:
          # Launch the 'secrets/profiledata' plugin to download agent secrets,
          # and the 'jenkins/swarm' plugin to start up as a Jenkins Swarm agent
          "CB_ENTRYPOINT_PLUGINS=secrets/profiledata jenkins/swarm"

          # Not strictly necessary as this is the default value
          "CB_ENTRYPOINT_BASE=https://cb-entry.s3.us-west-2.amazonaws.com"

          # Required for 'secrets/profiledata'
          "NODE_CLASS=build"
          "NODE_PRODUCT=couchbase-server"

          # Required for 'jenkins/swarm'
          "JENKINS_AGENT_NAME=universal-demo"
          "JENKINS_AGENT_LABELS=testing server linux"
          "JENKINS_URL=http://server.jenkins.couchbase.com/"

        # 'jenkins/swarm' installs a bespoke healthcheck, so we configure the
        # container to use it
        healthcheck:
          test: ["CMD", "/tmp/healthcheck.sh"]
          interval: 30s
          timeout: 90s
          retries 3

        secrets:
          # Required to bootstrap 'secrets/profiledata'
          - source: profiledata_ssh_key
            target: /run/secrets/profiledata_ssh_key

          # Required for 'jenkins/swarm' to contact Jenkins
          - source: server_jenkins_username
            target: /run/secrets/jenkins_username
          - source: server_jenkins_password
            target: /run/secrets/jenkins_password

    secrets:
      profiledata_ssh_key:
        external: true
      server_jenkins_username:
        external: true
      server_jenkins_password:
        external: true
