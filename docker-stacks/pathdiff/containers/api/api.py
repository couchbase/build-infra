#!/usr/bin/env python3

import binaries
import db
import flask
import json
import os
import redis
import threading
import time
from ast import literal_eval
from celery import Celery
from flask import request
from flask_cors import CORS, cross_origin
from shutil import copy

queue_poll_interval = 10
default_product = "couchbase-server"
default_edition = "enterprise"

celery = Celery(broker='redis://redis//')
r = redis.StrictRedis(host='redis', port='6379')
app = flask.Flask(__name__)
app.config['CORS_HEADERS'] = 'Content-Type'
app.config["DEBUG"] = True
cors = CORS(app)
queue = []


@app.route('/', methods=['GET'])
@cross_origin()
def api_home():
    return ""


@app.route('/api/v1/queue', methods=['GET'])
@cross_origin()
def api_queue():
    """ Return a list of currently processed/queued jobs """
    return json.dumps(queue)


@app.route('/api/v1/distros', methods=['GET'])
@cross_origin()
def api_distros():
    """ Retrieve a list of distros for which file lists have been gathered """
    return json.dumps([d[0] for d in db.query(
        "SELECT UNIQUE(distro) FROM listings WHERE status='ok' ORDER by distro ASC"
    )])


@app.route('/api/v1/versions', methods=['GET'])
@cross_origin()
def api_versions():
    """ Retrieve a list of versions (optionally for a given distro) """
    [distro, product] = map(request.args.get, ['distro', 'product'])
    if not product:
        product = default_product

    if distro:
        results = db.query(
            "SELECT UNIQUE(version) FROM listings WHERE status='ok' AND product=%s AND distro=%s ORDER by version ASC",
            (product, distro,)
        )
    else:
        results = db.query(
            "SELECT UNIQUE(version) FROM listings WHERE product=%s AND status='ok' ORDER by version ASC",
            (product, )
        )

    if results:
        return json.dumps([v[0] for v in results])

    return json.dumps({})


@app.route('/api/v1/listing', methods=['GET', 'POST'])
@cross_origin()
def api_listing():
    """
    GET: Retrieve a file/folder listing for a given distro + product + version + edition [+ build]
    POST: Remove any existing record, and add a listing to the database
    """
    global queue
    if request.method == "GET":
        [distro, product, version, build, edition, force] = map(
            request.args.get, ['distro', 'product', 'version', 'build', 'edition', 'force'])

        if not any([distro, version]):
            return f'{"error": "distro and version must be provided."}'

        if version.find("-") > 0:
            [version, build] = version.split("-")
        else:
            build = "GA"

        if not product:
            product = default_product
        if not edition:
            edition = default_edition

        return str(binaries.get_files(
            distro=distro, product=product, edition=edition, version=version, build=build, force=force, queue=queue
        ))

    elif request.method == "POST":
        payload = json.loads(request.form.get('payload'))
        db.exec(
            "DELETE FROM listings WHERE product=%s and edition=%s and version=%s and build=%s and distro=%s",
            (payload['product'], payload['edition'],
             payload['version'], payload['build'], payload['distro'])
        )
        db.exec(
            "INSERT INTO listings(status, product, edition, version, build, distro, files, url, runcmd, msg) VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (payload['status'], payload['product'], payload['edition'], payload['version'], payload['build'],
             payload['distro'], json.dumps(payload['files']), payload['url'], payload['runcmd'], payload['msg'])
        )
        return {}


@app.route('/api/v1/compare', methods=['GET'])
@cross_origin()
def api_compare():
    """ Retrieve a comparison between two versions """
    global queue
    [distro, product, from_version, to_version, edition] = map(
        request.args.get, ['distro', 'product', 'from_version', 'to_version', 'edition'])

    if from_version and to_version:

        if "-" not in from_version:
            from_version = f"{from_version}-GA"

        if "-" not in to_version:
            to_version = f"{to_version}-GA"

        [from_version, from_build] = from_version.split("-")
        [to_version, to_build] = to_version.split("-")

        from_listing = json.loads(binaries.get_files(
            distro, product, edition, from_version, from_build, queue=queue))

        to_listing = json.loads(binaries.get_files(
            distro, product, edition, to_version, to_build, queue=queue))

        new_binaries = list(
            set(to_listing['files']) - set(from_listing['files']))

        removed_binaries = list(
            set(from_listing['files']) - set(to_listing['files']))

        # note: paths aren't actually stored in the database. We figure those
        # out as a convenience in binaries.py/get_files()
        new_binary_dirs = list(
            set(to_listing['paths']) - set(from_listing['paths']))

        removed_binary_dirs = list(
            set(from_listing['paths']) - set(to_listing['paths']))

        return json.dumps({
            "distro": distro,
            "from_version": from_version,
            "from_build": from_build,
            "to_version": to_version,
            "to_build": to_build,
            "new_binary_dirs": sorted(new_binary_dirs),
            "removed_binary_dirs": sorted(removed_binary_dirs),
            "new_binaries": sorted(new_binaries),
            "removed_binaries": sorted(removed_binaries),
        })
    else:
        return {"error": "from and to must be provided."}


def monitor_queue():
    """
    This function runs in a thread to periodically poll the queue.
    We need to speak to redis and celery (which is slow and blocky)
    so rather than figure out what's queued on demand, we just do
    it every queue_poll_interval seconds and refer to the in memory
    results
    """
    global queue
    global queue_poll_interval
    while True:
        newqueue = []
        uniques = []
        # Check redis
        tasks = [json.loads(pending_task)['headers']
                 for pending_task in r.lrange('celery', 0, -1)]
        for task in tasks:
            t = literal_eval(task['argsrepr'])
            print(task)
            unique_ref = f"{t[0]}{t[1]}{t[2]}{t[3]}{t[4]}"
            if unique_ref not in uniques:
                uniques.append(unique_ref)
                newqueue.append({
                    "distro": t[0],
                    "product": t[1],
                    "edition": t[2],
                    "version": t[3],
                    "build": t[4],
                    "status": "queued"
                })
        # Check celery
        q = celery.control.inspect()
        for subset in ["active", "reserved"]:
            if eval(f"q.{subset}()"):
                for _, v in eval(f"q.{subset}().items()"):
                    for item in v:
                        [distro, product, edition, version, build] = item['args']
                        unique_ref = f"{distro}{product}{edition}{version}{build}"
                        if unique_ref not in uniques:
                            uniques.append(unique_ref)
                            newqueue.append({
                                            "distro": distro,
                                            "product": product,
                                            "edition": edition,
                                            "version": version,
                                            "build": build,
                                            "status": "processing" if subset == "active" else "queued"
                                            })
        queue = newqueue
        time.sleep(queue_poll_interval)


def main():
    db.bootstrap()
    thread = threading.Thread(target=monitor_queue)
    thread.start()
    app.run(threaded=True, host='0.0.0.0', port=5000)


if __name__ == "__main__":
    main()
