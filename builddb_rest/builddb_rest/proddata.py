"""
Module to give access to product metadata via requests in Cornice;
yes, the main method MUST be called 'includeme'
"""

import json
import os
import os.path
import pathlib


def read_json_file(datafile):
    """
    Read in given JSON file from the filesystem; handle any errors
    during processing properly
    """

    try:
        with open(datafile) as fh:
            return json.loads(fh.read())
    except FileNotFoundError:
        raise RuntimeError(
            f'Unable to open metadata file {datafile}'
        )
    except json.decoder.JSONDecodeError:
        raise RuntimeError(
            f'Invalid JSON in metadata file {datafile}'
        )


def load_product_metadata(datadir):
    """
    Find all 'allowed metadata' JSON files and organize the data
    in them based on product
    """

    md = dict()

    for root, dirs, files in os.walk(datadir):
        for data_file in files:
            if data_file != 'allowed-metadata.json':
                continue

            # Ensure current directory is 'metadata', otherwise fail;
            # if correct, the parent directory the product name
            curr_dir = pathlib.Path(root)

            if curr_dir.name != 'metadata':
                raise RuntimeError(
                    f'Invalid parent directory "{curr_dir.name}" '
                    f'for allowed-metadata.json file'
                )

            product = curr_dir.parent.name
            md[product] = read_json_file(curr_dir / data_file)

    return md


def includeme(config):
    """
    Load in product metadata and make it accessible to all
    requests generated via Cornice
    """

    settings = config.registry.settings
    datadir = pathlib.Path(settings["prod_metadata"])

    if not os.path.exists(datadir):
        raise RuntimeError(
            f'Missing product metadata directory: {datadir}'
        )

    try:
        settings["metadata"] = load_product_metadata(datadir)
    except RuntimeError as exc:
        raise RuntimeError(f'Failed to load in product metadata: {exc}')

    # Make product metadata location in accessible as a request property
    def _get_prod_metadata(request):
        _settings = request.registry.settings
        prod_metadata = _settings['metadata']

        return prod_metadata

    config.add_request_method(_get_prod_metadata, 'prod_metadata', reify=True)
