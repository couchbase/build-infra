import fnmatch
import importlib
import os
import re

from setuptools import setup

import build_database.version


# Let's add this later
# long_description = open('README.txt').read()


def discover_packages(base):
    """
    Discovers all sub-packages for a base package
    Note: does not work with namespaced packages (via pkg_resources
    or similar)
    """

    mod = importlib.import_module(base)
    mod_fname = mod.__file__
    mod_dirname = os.path.normpath(os.path.dirname(mod_fname))

    for root, _dirnames, filenames in os.walk(mod_dirname):
        for _ in fnmatch.filter(filenames, '__init__.py'):
            yield '.'.join(os.path.relpath(root).split(os.sep))


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
    name='build_database',
    version=build_database.version.__version__,
    description='Couchbase Build Team applications for build database',
    # long_description = long_description,
    author='Couchbase Build and Release Team',
    author_email='build-team@couchbase.com',
    license='Apache License, Version 2.0',
    packages=list(discover_packages('build_database')),
    install_requires=REQUIREMENTS['install'],
    entry_points={
        'console_scripts': [
            'load_build_database = build_database.scripts.load_build_database:main',
            'jira_commenter = build_database.scripts.jira_commenter:main',
            'add_commit_history = build_database.scripts.add_commit_history:main',
            'build_diff = build_database.tools.build_diff:main',
            'build_database_restapis = build_database.restapis.build_database_restapis:main'
        ]
    },
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved',
        'Operating System :: MacOS :: MacOS X',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 3.6',
        'Topic :: Database :: Front-Ends',
    ]
)

if __name__ == '__main__':
    setup(**setup_args)
