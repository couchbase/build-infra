# clean-nas

Script to clean up old files on NAS.

# Input

`patterns.yaml` contains instructions about what files to purge and
which to keep. The main data structure in this file is a STATE, which
defines the set of rules that should be applied to a directory and all
its subdirectories.

The form of a STATE is a yaml dictionary, which may have the following
keys:

1. `KEEP`: a regex matching filenames which should always be kept, even if
   they would otherwise be purged.
2. `REMOVE`: a mapping of filename regexes to integer ages. These regexes
   will be matched against the entire filename for every file
   (recursively) under the corresponding directory. Matching files that
   are older that the corresponding interval (in days) will be purged.
3. `REMOVE_EMPTY_DIRS`: a boolean. If `true`, then after purging files,
   any empty subdirectories will also be removed.
4. `SKIP`: a boolean. If `true`, this directory (and all subdirectories)
   will be entirely skipped. Can be used to avoid walking directories
   that we know will not contain expire-able builds.
5. `SUBDIRS`: a mapping of directory regexes to STATEs; see below.

There is a top-level key `rootdir` which corresponds to the root
directory passed to `clean_nas.py`, which should be the path to
latestbuilds. The value of `rootdir` is a STATE.

# Process

`clean_nas.py` walks a directory tree from a given root (which should be
latestbuilds). It first creates a set of rules from the `rootdir` STATE.
Then for each subdirectory of the root, it checks the regexes in the
STATE's `SUBDIRS`. If any of those regexes match, it creates a new STATE
from the value corresponding to that regex, and then walks the
subdirectory with the new STATE. This process is repeated recursively,
so each level of the latestbuilds tree may have different sets of
purging rules.

If, when walking, there are no `SUBDIRS` entries that match a given
subdirectory name, then the script will simply walk that subdirectory
with the current STATE's ruleset. At that point, that same ruleset will
be used for the entire subdirectory tree.

When entering a subdirectory that did correspond to a `SUBDIRS` entry,
the ruleset will be formed by *extending* the current directory's
ruleset with the new rules from the subdirectory's STATE. In this way,
rules are always applied recursively all the way down, but can be
modified at any level as necessary.

# Example

The current `patterns.yaml`'s `rootdir` key has the following value
(elided for brevity):

    REMOVE:
      ".*source.tar.gz": 2
    REMOVE_EMPTY_SUBDIRS: false

    SUBDIRS:
      "couchbase-lite-core":
        REMOVE:
          ".*(zip|tgz|tar.gz)": 90

      ...

This means:

1. When processing the root directory and all subdirectories, any file
   whose name matches `.*source.tar.gz` and that is more than 2 days old
   will be purged (due to `REMOVE`).
2. When processing the root directory and all subdirectories, after
   purging files, any empty directories will not be deleted (due to
   `REMOVE_EMPTY_SUBDIRS` being false).
3. When processing the root directory *only*, if a subdirectory matches
   `couchbase-lite-core`, then a new set of rules will be formed for
   that subdirectory and all its subdirectories that also purges files
   named `.*(zip|tgz|tar.gz)` that are more than 90 days old.

Since the `couchbase-lite-core`'s value does not have a `SUBDIRS` key,
then that new set of rules will be used for the entire directory tree
underneath `latestbuilds/couchbase-lite-core`. If there *had* been a
`SUBDIRS` key there, then it would have defined regexes to match
subdirectories directly under `latestbuilds/couchbase-lite-core` with
their own rules modifications.

# Ordering implementation details

## Directory regexes

PyYAML preserves key order when loading a document. Therefore the regex
keys of a `SUBDIRS` dictionary will be checked in order, and the first
matching entry will be used. That means it is possible to have a
more-specific entry override a more-generic entry so long as it is
first. For example:

    SUBDIRS:
      "specific-dir":
        REMOVE:
          ".*zip": 90

      ".*":
        REMOVE:
          ".*zip": 30

.zip files under `specific-dir` will be kept for 90 days, while .zip
files under any other subdirectories will be kept for 30 days.

## Filename regexes

When constructing rulesets, this script will merge regexes for the same
age into a large single regex. Then, when processing files in a
directory according to a ruleset, the script will check each combined
regex in ascending age order, so regexes with shorter expiration ages
will be checked first. Therefore it is possible to specify a generic
regex with one expiration period and a more-specific regex with a
*shorter* expiration period, but not a *longer* expiration period. For
example:

    REMOVE:
      ".*source.tar.gz": 2
      ".*tar.gz": 90

Since these regexes are checked in ascending age order, a file named
`couchbase-autonomous-operator_2.8.0-102-kubernetes-linux-amd64.tar.gz`
will be kept for 90 days, while one named
`couchbase-operator-2.8.0-102-source.tar.gz` will only be kept for 2
days. The same is true even if the rules are defined at different
subdirectory levels.
