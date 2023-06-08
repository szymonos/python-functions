"""
__init__.py.

init module for Azure function.
"""
import logging

# __app__/HttpTrigger/__init__.py
import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    """Says hello to user."""
    logging.info("Python HTTP trigger function processed a request.")
    logging.info("Request parameters: %s", dict(req.params.items()))

    name = req.params.get("name")
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get("name")

    if name:
        return func.HttpResponse(f"Hello {name}")
    return func.HttpResponse(
        "Please pass a name on the query string or in the request body", status_code=400
    )
