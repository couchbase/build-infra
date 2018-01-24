Modules for Build Database Schema Updates
=========================================

This directory contains modules that can be used to make schema updates
upon the build database without interrupting standard operations.  Please
note that the database loader should have the necessary updates made to
it first with a new image uploaded to Docker Hub for the Jenkins job to
use; once that's done, the update program can be used with the necessary
module.

Creating a New Module
---------------------

For a new schema update, create a new module with a descriptive but not
too long name (e.g. 'add_author_to_commit.py').  The module will need to
contain a class named 'UpdateDocuments', which the update program will
instantiate to do the changes to the various documents.  It must contain
at least the following two methods:

* `__init__(self, cb_info, repo_info)`
* `update_documents(self, document)`

For `__init__`, the 'cb_info' contains basic database configuration
information (e.g. DB URI), and the 'repo_info' contains basic repository
information (e.g. base directory for bare repos).  Within the method,
`self.doctype` must be set with the correct document type being worked
 upon for the update program to function.

For `update_documents`, 'document' contains the data for the document
being worked upon.  This method is what needs to manage the changes
themselves to said document.  Other methods can be added as needed to
make the necessary changes, but the update program depends on the
aforementioned methods to exist.

Running a Module
----------------

NOTE: This can probably be simplified with a bit of work, but the process
does work currently.

To run a given module, you'll need to start up a Docker container from
a host that contains the bare repositories used by the loader, and ensure
that the container mounts the parent directory, along with the needed
loader configuration file which should already exist on the proper host.
The Docker image `couchbasebuild/ubuntu-1604-python3.6-base` can be used
for the container and you'll need to ensure you can log into it:

```text
# docker run --rm -u couchbase \
    -v /home/couchbase/build_database/build_db_loader_conf.ini:/etc/build_db_loader_conf.ini \
    -v /home/couchbase/build_database:/home/couchbase/build_database \
    -it --entrypoint=/bin/bash couchbasebuild/ubuntu-1604-python3.6-base
```

Check out the `python-couchbase-common` and `build-infra` repositories,
then install the requirements for the needed modules in a virtualenv:

```text
# git clone https://github.com/couchbase/python-couchbase-commons.git
# git clone https://github.com/couchbase/build-infra.git
# python3.6 -m venv commit_update
# . ./commit_update/bin/activate
# (cd python-couchbase-commons && pip install -r requirements.txt)
# (cd build-infra/build_database && pip install -r requirements.txt)
```

Enter the `build_database` package directory in `build-infra`, and you
can now run the update program with the desired module:

```text
PYTHONPATH=/path/to/python-couchbase-commons/cbbuild:. ./scripts/update_build_database.py add_author_to_commit
```

The PYTHONPATH setting is necessary to find the needed `cbbuild` modules
as well as the the current directory where the `modules` directory is
located.  A progress 'bar' of dots will be seen as the program runs; each
dot represents 1,000 entries.  This is to let the user know that progress
is actually being made, allowing one to determine if the program might be
hung.
