#!/usr/bin/env python3

import argparse
import logging
import os
import re
import sys
import time
import yaml

from collections import defaultdict
from pathlib import Path
from typing import DefaultDict, Dict, Optional, Self


bytes_purged: int = 0

class CompiledRegex:
    """
    Simple bag that holds a string regex and the compiled version of
    that regex.
    """
    _regex: Optional[str]
    _compiled_regex: Optional[re.Pattern]

    def __init__(self, regex: Optional[str] = None):
        self._regex = regex
        self._compiled_regex = re.compile(self._regex) if regex else None

    def extend(self, regex: str) -> Self:
        """
        Returns a new CompiledRegex formed by appending "|{regex}" to
        the end of the current one; ie, the new CompiledRegex will match
        anything the original would, as well as anything that the new
        regex matches.
        """

        if self._regex:
            return CompiledRegex(f"{self._regex}|{regex}")
        else:
            return CompiledRegex(regex)

    def matches(self, string: str) -> bool:
        """
        Returns True if the string matches the current regex.
        """

        if self._compiled_regex:
            return self._compiled_regex.fullmatch(string)
        else:
            return False


class PurgeRules:
    """
    Represents a the set of rules active at a particular directory
    level, including:

    1. A regex of filenames that should be kept
    2. A set of regexes of filenames that may be purged, each associated
       with an age parameter (in days)
    3. Whether empty directories should be deleted
    """

    _keep: CompiledRegex
    _purge_map: DefaultDict[int, CompiledRegex]
    _remove_empty_dirs: bool
    _skip: bool
    _dryrun: bool

    def __init__(self, dryrun: bool):
        self._purge_map = defaultdict(lambda: CompiledRegex())
        self._keep = CompiledRegex()
        self._remove_empty_dirs = False
        self._skip = False
        self._dryrun = dryrun

    def derived(self, state: Dict) -> Self:
        """
        Returns a potentially-new PurgeRules object modified by the
        REMOVE, KEEP, REMOVE_EMPTY_DIRS, and SKIP entries in 'state'. If
        there are no such entries, returns self.
        """

        if not state:
            return self

        if not any(
            x in state for x in ("REMOVE", "KEEP", "REMOVE_EMPTY_DIRS", "SKIP")
        ):
            return self

        # Create a new empty rules object. Next steps will either
        # override or pass through each of the data members.
        newrules = PurgeRules(self._dryrun)

        if "REMOVE" in state:
            # Make a shallow copy of the current remove_set - we want to
            # keep all those rules and only modify any that are changed
            # here
            newrules._purge_map = self._purge_map.copy()

            # Extend any intervals in the buffer that are modified at
            # this level
            for regex, period in state["REMOVE"].items():
                logging.debug(f"Adding regex {regex} to purge rules")
                newrules._purge_map[period] = \
                    newrules._purge_map[period].extend(regex)
        else:
            newrules._purge_map = self._purge_map

        if "KEEP" in state:
            # Extend the buffer with any items defined at this level
            for regex in state["KEEP"]:
                logging.debug(f"Adding regex {regex} to keep rule")
                newrules._keep = newrules._keep.extend(regex)
        else:
            newrules._keep = self._keep

        # Override these booleans if set, otherwise keep current value

        newrules._remove_empty_dirs = \
            state.get("REMOVE_EMPTY_DIRS", self._remove_empty_dirs)
        newrules._skip = state.get("SKIP", self._skip)

        return newrules

    def should_skip(self) -> bool:
        """
        Returns True if rules have SKIP: true
        """

        return self._skip

    def purge_files(self, directory: Path):
        """
        Applies file rules to a given directory: files that match a
        purge regex and are older than the associated age will be
        deleted, unless they also match a keep regex.
        """

        current_time = time.time_ns()
        for file in directory.iterdir():
            # Only apply rules to files (not dirs or symlinks)
            if not file.is_file() or file.is_symlink():
                continue

            # First check keep RE - trumps all purge rules
            if self._keep.matches(file.name):
                continue

            # Check all purge REs - check longest expiry age patterns
            # first, so that more-specific regexes can override
            # more-generic regexes with longer expiry ages
            for age in sorted(self._purge_map):
                re = self._purge_map[age]
                if not re.matches(file.name):
                    continue

                # Possibly need to delete - check file age. Use integer
                # st_mtime_ns rather than floating-point st_mtime.
                stats = file.stat()
                mtime = stats.st_mtime_ns
                if (current_time - mtime) > (age * 24 * 3600 * 1000000000):
                    if self._dryrun:
                        logging.info(f"NOT purging {file} due to {re._regex} (--dry-run)")
                    else:
                        logging.info(f"Purging {file}")
                        file.unlink()
                    global bytes_purged
                    bytes_purged += stats.st_size

                # Stop checking purge REs after first match, whether or
                # not the file was deleted.
                break


    def purge_empty_subdirs(self, directory: Path):
        """
        If rules request deleting empty subdirectories, do so
        """

        if not self._remove_empty_dirs:
            return

        for subdir in directory.iterdir():
            if not subdir.is_dir() or subdir.is_symlink():
                continue

            # If the directory iterator returns None immediately, the
            # dir is empty
            if not next(subdir.iterdir(), None):
                if self._dryrun:
                    logging.info(f"NOT deleting empty directory {subdir}/ (--dry-run)")
                else:
                    logging.info(f"Deleting empty directory {subdir}/")
                    subdir.rmdir()


def enter_dir(directory: Path, rules: PurgeRules, state: Optional[Dict]):
    """
    Recursive function to walk a directory subtree, purging files
    according to the PurgeRules. If `state` is not empty, then it will
    be used to update the PurgeRules and also to provide derived states
    to any subdirectories with names matching entries under `SUBDIRS` in
    the state.
    """

    if state:
        # Update the purge rules based on the current state level
        rules = rules.derived(state)

        # If the new rules say "SKIP", then quit out immediately
        if rules.should_skip():
            logging.info(f"Skipping directory {directory}")
            return

        # If we have a `state`, this is an "important" directory, so log
        # at info level.
        logging.info(f"Entering directory {directory}")

        # Also pull out SUBDIRS while we're here.
        subdirs = state.get("SUBDIRS")
    else:
        # No `state`, so "just" a subdirectory; log at debug level.
        logging.debug(f"Entering directory {directory}")
        subdirs = None

    # Apply purge rules to current directory
    rules.purge_files(directory)

    # And walk down into any subdirectories. If the current state has
    # SUBDIRS, walk into any matching subdirectories with the
    # corresponding updated state.
    for subdir in directory.iterdir():
        if not subdir.is_dir() or subdir.is_symlink():
            continue

        # If no subdirs declared, walk down with an *empty* state; the
        # current purge rules will be used all the way down that
        # directory subtree
        if not subdirs:
            enter_dir(subdir, rules, state=None)
            continue

        # Pick a subdirs entry that matches the current directory name
        for subdir_re, subdir_state in subdirs.items():
            # We could be neat and pre-compile all these regexes.
            # However, they'll only be used right now, and the re module
            # caches several recent compilations anyway, so it wouldn't
            # make any real difference.
            logging.debug(f"considering `{subdir_re}` for {subdir.name}/")
            if re.fullmatch(subdir_re, subdir.name):
                enter_dir(subdir, rules, state=subdir_state)
                # Stop checking subdir REs after we enter a directory
                break
        else:
            # If we got here, none of the SUBDIRS matched, so just
            # recurse with the current rules and an empty state
            logging.debug(f"no SUBDIRS rules matched, entering {subdir} with current rules")
            enter_dir(subdir, rules, state=None)

    # After walking subdirectories, delete empty subdirs if requested
    rules.purge_empty_subdirs(directory)

    if state:
        logging.info(f"Exiting directory {directory}")


def main():
    arg_parser = argparse.ArgumentParser(description="Clean old NAS files")
    arg_parser.add_argument("-n", "--dry-run", action="store_true",
                            help="Only display what would be done")
    arg_parser.add_argument("-v", "--verbose", action="store_true",
                            help="Output debug information")
    arg_parser.add_argument("root", type=str, help="Root directory to walk")
    args = arg_parser.parse_args()

    logging.basicConfig(
        stream=sys.stderr,
        format='%(asctime)s: %(levelname)s: %(message)s',
        level=logging.DEBUG if args.verbose else logging.INFO
    )

    patterns_file = Path(__file__).parent / "patterns.yaml"
    with patterns_file.open() as p:
        patterns = yaml.safe_load(p)

    # Just to keep the paths trimmed in the logs, chdir into the parent
    # of the root dir and then use a relative Path for it
    root = Path(args.root).resolve()
    os.chdir(root.parent)
    enter_dir(
        Path(root.name), PurgeRules(args.dry_run), patterns["rootdir"]
    )

    global bytes_purged
    logging.info(f"Done!")
    if args.dry_run:
        logging.info(f"{bytes_purged} bytes NOT purged (--dry-run)")
    else:
        logging.info(f"{bytes_purged} bytes purged")
