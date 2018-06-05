Documentation
=============

This is the initial (v1) version of the REST API for the build database,
managed by the Build Team.  It is a work in progress, and currently contains
the following endpoints (**NOTE**: all endpoints have a version prefix '/v1'):

Builds
######

* /products
* /products/*product_name*
* /products/*product_name*/releases
* /products/*product_name*/releases/*release_name*
* /products/*product_name*/releases/*release_name*/versions
* /products/*product_name*/releases/*release_name*/versions/*version*
* /products/*product_name*/releases/*release_name*/versions/*version*/builds
* /products/*product_name*/releases/*release_name*/versions/*version*/builds/*build_num*
* /builds
* /builds/*product-version-build_num*

The last two are concise (document-name-specific) path versions of the
previous two (known as the full path versions).

Commits
#######

* /projects
* /projects/*project_name*
* /projects/*project_name*/commits
* /projects/*project_name*/commits/*SHA*
* /commits
* /commits/*project-SHA*

The last two are concise (document-name-specific) path versions of the
previous two (known as the full path versions).
