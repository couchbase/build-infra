# Adding products to worker

worker.py will import files from this dir, named for the ${product} it is operating on.

To add additional products, you'll just need to create a ${product}.py file here, containing a class named **Docker** which adheres to the following structure:

    class Docker():
        def __init__(self, distro=None, product=None, edition=None, version=None, build=None):
            self.url
            self.runcmd
            self.binary_files

        def run(self):
            pass

Consider that an object will be instantiated from this class, it will be .run(), and afterwards, .url, .runcmd and .binary_files should be available - url and runcmd are for troubleshooting purposes and should contain the URL of any package installed and the commands executed in the container respectively. binary_files should be a list of individual files which were identified.

You can look at get_listing in worker.py for a greater understanding. It's quite short, and is the only place these modules are accessed.