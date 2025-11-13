import pytest

INJECTION_PAYLOADS = [
    "' OR 1=1--",
    "'; DROP TABLE users; --",
    '" OR ""="',
    "1; SELECT pg_sleep(1); --",
]


@pytest.mark.security
@pytest.mark.parametrize("payload", INJECTION_PAYLOADS)
def test_sql_injection_like_inputs_are_handled(client, payload):
    # Use /ask as a generic text-taking endpoint; change to your own endpoint if needed.
    resp = client.post("/ask", json={"question": payload})
    # Must not 5xx and must not leak driver/DB error signatures
    assert resp.status_code < 500, resp.text
    body = resp.text.lower()
    forbidden_markers = [
        "sql syntax",
        "sqlite error",
        "psycopg",
        "mysql",
        "odbc",
        "sqlstate",
        'near "',
    ]
    assert not any(m in body for m in forbidden_markers), f"Leaked DB error: {body}"
