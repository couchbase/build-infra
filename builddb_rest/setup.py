import re
import runpy

from setuptools import setup, find_packages


# Let's add this later
# with open(os.path.join(here, 'README.rst')) as f:
#     long_description = f.read()

# Import version this way, since Cornice's need to use __init__.py
# causes a Catch-22 for trying to import the module
file_globals = runpy.run_path('builddb_rest/version.py')
prog_version = file_globals['__version__']


def reqfile_read(fname):
    with open(fname, 'r') as reqfile:
        reqs = reqfile.read()

    return filter(None, reqs.strip().splitlines())


def load_requirements(fname):
    requirements = list()

    for req in reqfile_read(fname):
        if 'git+' in req:
            subdir_re = re.compile(r'&subdirectory=.+$')
            req = '=='.join(
                re.sub(subdir_re, r'', req).rsplit('=')[-1].split('-', 3)[:2]
            )
        if req.startswith('--'):
            continue
        requirements.append(req)

    return requirements


REQUIREMENTS = dict()
REQUIREMENTS['install'] = load_requirements('requirements.txt')


setup_args = dict(
    name='builddb_rest',
    version=prog_version,
    description='REST API for Build Team database',
    # long_description=long_description,
    classifiers=[
        "Programming Language :: Python",
        "Framework :: Pylons",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application"
    ],
    keywords="web services",
    author='Couchbase Build and Release Team',
    author_email='build-team@couchbase.com',
    license='Apache License, Version 2.0',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    install_requires=REQUIREMENTS['install'],
    entry_points="""
    [paste.app_factory]
    main=builddb_rest:main
    """,
    paster_plugins=['pyramid']
)

if __name__ == '__main__':
    setup(**setup_args)
