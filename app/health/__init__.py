"""
__init__.py.

init module for health Azure function.
"""
import json
import logging
import os

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    """Initialize etl function."""
    try:
        img_tag: object = os.environ["IMG_TAG"]
    except KeyError:
        img_tag = None

    logging.info("Container image Tag: %s", img_tag)
    logging.info("Request parameters: %s", dict(req.params.items()))

    response = {"status": "Healthy", "message": img_tag}
    return func.HttpResponse(
        body=json.dumps(response), status_code=200, mimetype="application/json"
    )
