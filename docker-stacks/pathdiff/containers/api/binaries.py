import db
import json
import os
import redis
from ast import literal_eval
from celery import Celery

celery = Celery(broker='redis://redis//')
r = redis.StrictRedis(host='redis', port='6379')
versions = []


def indexed(product, edition, version, build, distro):
    """ Determine if a given build has been indexed """
    return db.query(
        "SELECT * FROM listings WHERE distro=%s product=%s version=%s build=%s edition=%s",
        (distro, product, version, build, edition)
    )


def get_files(distro=None, product=None, edition=None, version=None, build=None, force=False, queue=[]):
    """ Retrieve a list of files and paths for a given version of product """
    if not build or build == "undefined":
        build = "GA"
    # Check the database first to see if we already have the info
    existing_listing = db.query(
        "SELECT status, files, msg FROM listings WHERE distro=%s AND product=%s AND version=%s AND build=%s AND edition=%s",
        (distro, product, version, build, edition)
    )
    if existing_listing and not force:
        # It's in the database and we're not forcibly reindexing, return info from db
        return json.dumps(({
            "status": existing_listing[0][0],
            "distro": distro,
            "product": product,
            "version": version,
            "edition": edition,
            "build": build,
            "files": sorted(json.loads(existing_listing[0][1])),
            "paths": sorted(set(os.path.dirname(binary) for binary in json.loads(existing_listing[0][1]))),
            "msg": existing_listing[0][2].decode("utf-8") if existing_listing[0][2] != None else ""
        }))
    # Couldn't find it in the database, let's check the queue
    if len(queue) > 0:
        for q in queue:
            # It's in the queue, notify
            if q['product'] == product and q['version'] == version and q['edition'] == edition and q['build'] == build and q['distro'] == distro:
                return json.dumps({"status": "pending", "msg": f"Already queued: {product}-{version}-{edition}-{build} ({distro})"})
    try:
        # Not queued, attempt to queue it up
        celery.send_task(
            'get_listing', (distro, product, edition, version, build))
        return json.dumps({"status": "queued", "msg": f"Added to queue: {product}-{version}-{edition}-{build} ({distro})"})
    except Exception as e:
        return json.dumps({"status": "dead", "msg": f"Couldn't queue task"})
