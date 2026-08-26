"""
Demo workload that fetches its secrets via Vault Kubernetes auth.
In production, this runs as a Kubernetes pod with a service account token.
"""
from __future__ import annotations
import os, time
import hvac
from fastapi import FastAPI
import uvicorn

VAULT_ADDR = os.getenv("VAULT_ADDR", "http://vault:8200")
VAULT_ROLE = os.getenv("VAULT_ROLE", "app-role")
SECRET_PATH = os.getenv("SECRET_PATH", "secret/data/app/config")
SA_TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"

app = FastAPI(title="Workload Identity Demo")
_secrets_cache = {}
_cache_expires = 0


def get_vault_client() -> hvac.Client:
    """Authenticate to Vault using the Kubernetes service account token."""
    client = hvac.Client(url=VAULT_ADDR)
    if os.path.exists(SA_TOKEN_PATH):
        with open(SA_TOKEN_PATH) as f:
            jwt = f.read().strip()
        client.auth.kubernetes.login(role=VAULT_ROLE, jwt=jwt)
    else:
        # Dev mode: use VAULT_TOKEN env var
        client.token = os.getenv("VAULT_TOKEN", "dev-root-token")
    assert client.is_authenticated(), "Failed to authenticate with Vault"
    return client


def fetch_secrets(force_refresh: bool = False) -> dict:
    """Fetch secrets from Vault with a 5-minute in-memory cache."""
    global _secrets_cache, _cache_expires
    if not force_refresh and time.time() < _cache_expires:
        return _secrets_cache
    try:
        client = get_vault_client()
        data = client.secrets.kv.v2.read_secret_version(path="app/config")
        _secrets_cache = data["data"]["data"]
        _cache_expires = time.time() + 300  # 5 min cache
        return _secrets_cache
    except Exception as e:
        if _secrets_cache:
            return _secrets_cache  # return stale cache on error
        raise RuntimeError(f"Cannot fetch secrets from Vault: {e}")


@app.get("/health")
def health():
    return {"status": "ok", "vault": VAULT_ADDR, "role": VAULT_ROLE}


@app.get("/api/v1/secrets/status")
def secrets_status():
    """Check that secrets are accessible (does NOT expose values)."""
    try:
        secrets = fetch_secrets()
        return {"status": "ok", "keys_available": list(secrets.keys()), "cached": time.time() < _cache_expires}
    except Exception as e:
        return {"status": "error", "detail": str(e)}


@app.post("/api/v1/secrets/refresh")
def refresh_secrets():
    """Force refresh the secrets cache."""
    secrets = fetch_secrets(force_refresh=True)
    return {"status": "refreshed", "keys": list(secrets.keys())}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
