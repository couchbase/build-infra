# This is a Very Special universal entrypoint plugin - it implements
# most of the actual Universal Entrypoint logic. It is invoked by the
# skeleton `universal_entrypoint.sh` script, such that we can deploy
# updates and bugfixes to most of the Universal Entrypoint logic without
# requiring container rebuilds.

# This script may also be invoked directly as a bash script (by the
# add_group() function), so it is important that any variables it uses
# are exported.

#
# Internal-only function (not intended for use by plugin scripts)
#

function _get_script() {
    local script_type=$1  # "plugin" or "healthcheck"
    local script_name=$2  # without .sh extension
    local dest_file=$3

    local dest_dir=$(dirname "${dest_file}")
    mkdir -p "${dest_dir}"

    # Relative path - the "s" makes the directory name plural, eg.
    # "plugins" or "healthchecks"
    local script="${script_type}s/${script_name}.sh"

    if [ ! -z "${CB_DEBUG_LOCAL_PLUGINS}" ]; then

        local local_file="${CB_ENTRYPOINT_LOCAL_ROOT}/${script}"
        if [ ! -f "${local_file}" ]; then
            abort "Local file not found: ${local_file}"
        fi
        status "Copying local ${script_type}: ${script_name}"
        cp "${local_file}" "${dest_file}"

    else

        local url="${CB_ENTRYPOINT_BASE}/${script}"
        status "Downloading ${script_type}: ${script_name}"
        curl -fsSL "${url}" > "${dest_file}"

    fi
}

#
# Functions available for use by plugin scripts
#

function header() {
    echo
    echo ":::::::::::::::::::::::::::::"
    echo ":: $@"
    echo ":::::::::::::::::::::::::::::"
    echo
}

function status() {
    # Print message after a series of dashes of length DEPTH
    local DASHES=$(printf "%${DEPTH}s" | tr ' ' '-')
    echo "${DASHES} $@"
}

function abort() {
    echo "CONTAINER ABORT (${CB_CURRENT_PLUGIN:-entrypoint}): $@" 1>&2
    exit 1
}

# Ensures that the specified environment variables are set
function chk_set {
    for var in $@; do
      # ${!var} is a little-known bashism that says "expand $var and then
      # use that as a variable name and expand it"
      if [[ -z "${!var}" ]]; then
          abort "\$${var} must be set in the environment!"
      fi
    done
}

# Ensures that the specified files are readable
function chk_file {
    for file in "$@"; do
        if [ ! -r "${file}" ]; then
            abort "Required file '${file}' not found!"
        fi
    done
}

# Ensures that the specified commands are available
function chk_cmd {
    for cmd in $@; do
        command -v $cmd > /dev/null 2>&1 || {
            abort "command '$cmd' not available!"
        }
    done
}

# Invokes a plugin script
function invoke_plugin() {
    local plugin_name=${1}
    local plugin=${plugin_name}.sh

    # Check if the plugin has already been downloaded
    local plugin_file="${CB_ENTRYPOINT_PLUGIN_CACHE}/${plugin}"
    if [ ! -f "${plugin_file}" ]; then
        local plugin_dir=$(dirname "${plugin_file}")
        _get_script plugin "${plugin_name}" "${plugin_file}"
    fi

    status "Invoking plugin: ${plugin_name}"
    # Increment the depth for status messages output by the plugin
    export DEPTH=$((DEPTH + 2))
    source "${plugin_file}"
    export DEPTH=$((DEPTH - 2))
    status "Plugin complete: ${plugin}"
}

# Installs a healthcheck script to `/tmp/healthcheck.sh`
function install_healthcheck() {
    local healthcheck_name=${1}
    local healthcheck=${healthcheck_name}.sh

    status "Installing healthcheck: ${healthcheck_name}"
    _get_script healthcheck "${healthcheck_name}" "/tmp/healthcheck.sh"
    chmod +x "/tmp/healthcheck.sh"
}

# Adds a unix group to the process. This is unfortunately pretty tricky;
# we actually have to re-invoke this script using the "sg" command,
# which creates a new subprocess. As such, this function does not
# return; plugins that use this function should call it last.
function add_group() {
    local group=${1}

    chk_cmd sg

    status "Adding unix group to entrypoint process: ${group}"

    # Fake the output from the end of invoke_plugin()
    export DEPTH=$((DEPTH - 2))
    status "Plugin complete: ${CB_CURRENT_PLUGIN}"

    # Re-invoke this universal/entrypoint plugin script
    exec sg ${group} "bash -e ${CB_ENTRYPOINT_PLUGIN_CACHE}/universal/entrypoint.sh"
}

#
# End of plugin functions
#

# Things we need to do only once, the first time we're invoked. These
# steps will be skipped if this script is re-invoked by add_group().
if [ -z "${CB_ENTRYPOINT_RESTART}" ]; then

    # Prevent re-executing this block if the script is re-invoked
    export CB_ENTRYPOINT_RESTART=1

    # Ensure that the script is not being run as root
    if [ "$(id -u)" == "0" ]; then
        abort "This image must not be invoked as the root user"
    fi

    # Initialize the depth for status messages
    export DEPTH=2

    # Dump environment and list plugins we're going to invoke
    header "Environment at container startup"
    env
    header "User ID at container startup"
    id
    echo
    echo ":::::::::::::::::::::::::::::"
    echo ":: Declared entrypoint plugins: [ ${CB_ENTRYPOINT_PLUGINS} ]"
    if [ ! -z "${CB_DEBUG_LOCAL_PLUGINS}" ]; then
        echo ":: Using local plugins in ${CB_ENTRYPOINT_LOCAL_ROOT}/plugins"
    else
        echo ":: Downloading from: ${CB_ENTRYPOINT_BASE}/plugins"
    fi
    echo ":::::::::::::::::::::::::::::"
    echo

    # For debugging purposes, if CB_DEBUG_ENTRYPOINT is set, enable shell tracing
    if [ ! -z "${CB_DEBUG_ENTRYPOINT}" ]; then
        set -x
    fi
fi

# Main loop to invoke each plugin
declare -i length
for plugin in ${CB_ENTRYPOINT_PLUGINS}; do
    export CB_CURRENT_PLUGIN=${plugin}

    # Trim down CB_ENTRYPOINT_PLUGINS in case we get re-invoked.
    length=${#plugin}+1
    export CB_ENTRYPOINT_PLUGINS="${CB_ENTRYPOINT_PLUGINS:${length}}"

    invoke_plugin ${plugin}
done
