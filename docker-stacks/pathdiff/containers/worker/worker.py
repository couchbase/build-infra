import importlib
import json
import os
import requests
import sys
from celery import Celery

# We'll be using importlib to import modules inside get_listing
# so we need to make sure we can find those imports
sys.path.append('.')

app = Celery('tasks', broker='redis://redis//')


def add_listing(status, distro, product, version, build, edition, url, files=[], runcmd="", error=None):
    # Once a worker has retrieved data, it posts back to the API for handling
    payload = {'status': status, 'distro': distro, 'product': product, 'version': version,
               'build': build, 'edition': edition, 'files': files, 'url': url, 'runcmd': runcmd, 'msg': error}
    requests.post(f'http://api:5000/api/v1/listing',
                  data={'payload': json.dumps(payload)})


@app.task(name='get_listing')
def get_listing(distro, product, edition, version, build):
    handler = importlib.import_module("products.%s" % product)

    print(
        f"Retrieving binary listing for {product}-{edition}-{version}-{build} ({distro})")

    if build == "undefined":
        build = "GA"

    container = handler.Docker(distro=distro, product=product,
                       edition=edition, version=version, build=build)

    try:
        container.run()
    except RuntimeError as e:
        # if container.run() hit an exception, we add a listing with the
        # info we have and a status of "error"
        add_listing("error", distro, product, version, build,
                    edition, container.url, [], container.runcmd, str(e))
        raise(e)

    if container.binary_files:
        # if container.run() was successful and we got a list of files
        # use add_listing() to fire them at the api
        add_listing("ok", distro, product, version, build, edition,
                    container.url, container.binary_files, container.runcmd)
    else:
        # container.run() was successful but we didn't get a list of files.
        # consider that an error
        add_listing("error", distro, product, version, build, edition,
                    container.url, [], container.runcmd, "no files found")
