
# code-pattern-match

This container syncs a manifest and runs The Silver Searcher against the downloaded code to identify undesirable patterns.

Usage: `docker run --rm -v ~/.ssh/foo:/root/.ssh/id_rsa -it couchbasebuild/code-pattern-matcher`

The patterns are described in patterns.json. Environment variables can be passed in to dictate manifest url/file/groups, for example:

`docker run --rm -v ~/.ssh/foo:/root/.ssh/id_rsa -it -e MANIFEST_FILE=couchbase-server/mad-hatter.xml couchbasebuild/code-pattern-matcher`

These default to:

MANIFEST_URL: ssh://git@github.com/couchbase/manifest
MANIFEST_FILE: branch-master.xml
MANIFEST_GROUPS: analytics,backup,build,cbgt,default,enterprise,kv,n1fty,packaging,query
