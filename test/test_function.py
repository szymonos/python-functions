"""
Unit tests for function HttpRequest.

:Execution
    pytest test --doctest-modules --junitxml=junit/coverage.xml
"""

import azure.functions as func
import function


# @pytest.mark.skip(reason='Disabled test')
def test_output_contacts():
    """Test function."""
    # Construct a mock HTTP request.
    req = func.HttpRequest(
        method="GET", body=None, url="/api/HttpTrigger", params={"name": "Test"}
    )

    # Call the function.
    resp = function.main(req)

    # Check the output.
    assert resp.get_body().decode() == "Hello Test"
