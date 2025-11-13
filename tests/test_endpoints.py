import pytest


@pytest.mark.security
def test_predict_endpoint_exists(client):
    resp = client.post("/predict", json={"input": "hello"})
    assert resp.status_code in (200, 400, 422), resp.text  # existence + sane handling


@pytest.mark.security
def test_ask_endpoint_exists(client):
    resp = client.post("/ask", json={"question": "What is 2+2?"})
    assert resp.status_code in (200, 400, 422), resp.text
