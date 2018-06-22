import fnmatch
import importlib
import os

from setuptools import setup

import jenkins_monitor.version


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


def load_requirements(fname):
    with open(fname, 'r') as reqfile:
        reqs = reqfile.read()

    return list(filter(None, reqs.strip().splitlines()))


REQUIREMENTS = dict()
REQUIREMENTS['install'] = load_requirements('requirements.txt')


setup_args = dict(
    name='monitor_jenkins',
    version=jenkins_monitor.version.__version__,
    description='Monitor basic Jenkins functions',
    # long_description = long_description,
    author='Couchbase Build and Release Team',
    author_email='build-team@couchbase.com',
    license='Apache License, Version 2.0',
    packages=list(discover_packages('jenkins_monitor')),
    include_package_data=True,
    install_requires=REQUIREMENTS['install'],
    entry_points={
        'console_scripts': [
            'monitor_jenkins = jenkins_monitor.scripts.monitor_jenkins_prog:main',
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
    ]
)

if __name__ == '__main__':
    setup(**setup_args)
