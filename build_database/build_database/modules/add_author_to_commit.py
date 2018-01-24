"""
Module to add several new keys to existing commit documents:
    - project and sha (separated for ease of use)
    - author
    - committer

The last two are extracted from the Git repositories for each project
"""

import logging
import pathlib
import sys

import cbbuild.cbutil.db as cbutil_db
import cbbuild.cbutil.git as cbutil_git


# Set up logging and handler
logger = logging.getLogger('build_database.modules.add_author_to_commit')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
logger.addHandler(ch)


class UpdateDocuments:
    """Handle updating the 'commit' documents in the build database"""

    def __init__(self, db_info, repo_info):
        """Set up information for database and repository access"""

        self.doctype = 'commit'  # Used for framework

        self.db = cbutil_db.CouchbaseDB(db_info)
        self.repo_base_dir = pathlib.Path(repo_info['repo_basedir'])
        self.repo_cache = cbutil_git.RepoCache()

    def get_remote(self, proj_name, url):
        """
        Retrieve a remote named based on the project name and URL;
        uses the project documents in the build database to determine
        this, returning None of the URL can't be found
        """

        key_name = f'project:{proj_name}'

        try:
            project_data = self.db.get_document(key_name)
        except cbutil_db.NotFoundError:
            logger.error(f"Project document '{key_name}' not found "
                         f"in database, aborting")
            sys.exit(1)

        for remote in project_data['remotes']:
            if url in project_data['remotes'][remote]:
                return remote
        else:
            return None

    def update_documents(self, document):
        """
        Several new keys are being added to the commit documents in
        the build_database:
            - project and sha (to make certain things easier)
            - author
            - committer
        A new document is generated to preserve order of the keys (since
        Python 3.6 databases do so by default)
        """

        # Document is already updated, skip
        if 'author' in document:
            return

        commit_name = document['key_']
        remote_url = document['remote']
        project, sha = commit_name.rsplit('-', 1)

        # Acquire remote and get cached repository (necessary for this
        # to properly work, will fail if not found)
        remote = self.get_remote(project, remote_url)

        if remote is None:
            logger.error(f"Remote URL '{remote_url}' not found in project "
                         f"document 'project:{project}', aborting")
            sys.exit(1)

        repo = self.repo_cache.get_repo(
            project, self.repo_base_dir / project, remote, remote_url
        )

        try:
            commit = repo.get_object(sha.encode('utf-8'))
        except KeyError:
            print(f"Commit b'{sha}' not found in repository '{project}' "
                  f"under remote '{remote}', aborting")
            sys.exit(1)

        # Build new document to keep keys in same order as existing
        # updated documents
        new_document = dict(type='commit', key_=commit_name)
        new_document['project'] = project
        new_document['sha'] = sha
        new_document['in_build'] = document['in_build']
        new_document['author'] = commit.author.decode(errors='replace')
        new_document['committer'] = commit.committer.decode(errors='replace')
        new_document['summary'] = document['summary']
        new_document['timestamp'] = document['timestamp']
        new_document['parents'] = document['parents']
        new_document['remote'] = remote_url

        self.db.upsert_documents({commit_name: new_document})
