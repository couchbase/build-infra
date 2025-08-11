This contains the Dockerfile for couchbasebuild/zzz-lightweight, which
is used by the `zzz-lightweight` agent on server.jenkins (and hopefully
others). The primary difference between this and the older
cocuhbasebuild/zz-lightweight is that this image doesn't install a bunch
of Python packages globally, and has `uv` on the PATH. Jobs using this
image are encouraged to use `uv` for all Python management, and not
depend on any Python packages install globally or at the user level.
