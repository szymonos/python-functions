"""
Unit tests for input module.

:Execution
    pytest test --doctest-modules --junitxml=junit/coverage.xml
"""

import azure.functions as func
import health


def test_health_check():
    """Unit test transforming contacts into rawzone."""
    req = func.HttpRequest(method="GET", body=None, url="/api/health")

    response = health.main(req)
    assert response.status_code == 200
