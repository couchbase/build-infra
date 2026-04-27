# Traefik Reverse Proxy

Traefik reverse proxy deployed as a Docker Swarm stack on `mega4.build.couchbase.com`. It provides TLS termination and routing for services across multiple docker-stacks.

## Architecture

- **Stack name:** `traefik` (resources get a `traefik_` prefix)
- **Network:** `traefik_reverse-proxy` (overlay, attachable) -- other stacks attach to this network and use Traefik labels for routing
- **TLS config:** `traefik-config.yaml` defines certificate file paths; Docker secrets supply the actual cert/key files
- **Deployment:** 3 replicas pinned to manager nodes

## Wildcard Certificates

Two wildcard certificates are managed via Docker Swarm secrets:

| Domain | Cert secret | Key secret |
|---|---|---|
| `*.build.couchbase.com` | `wildcard_build_couchbase_com_cert_YYYYMMDD` | `wildcard_build_couchbase_com_key_YYYYMMDD` |
| `*.couchbase.com` | `wildcard_couchbase_com_cert_YYYYMMDD` | `wildcard_couchbase_com_key_YYYYMMDD` |

The `YYYYMMDD` suffix is a date stamp used to version each secret (Docker Swarm secrets are immutable, so a new name is required each time).

`traefik.yaml` maps these versioned external secret names to stable aliases (e.g. `wildcard_build_couchbase_com_cert`) which the service mounts into `/certs/`.

## Updating Certificates

When new certificate files are issued, you'll typically receive:

- An **archive** containing:
  - A `.pem` file (the certificate)
  - A `.crt` file (the certificate, alternate format)
  - A `.bundle` file (intermediate/root CA chain)
- A separate **private key** `.pem` file

### Step-by-step

#### 1. Prepare the cert file

Traefik expects a single cert file containing the full chain. Concatenate the certificate and the CA bundle:

```sh
cat wildcard.build.couchbase.com.crt wildcard.build.couchbase.com.bundle > wildcard.build.couchbase.com.chained.crt
```

Verify the chain is valid:

```sh
openssl verify -CAfile wildcard.build.couchbase.com.bundle wildcard.build.couchbase.com.crt
```

#### 2. Create new Docker secrets on the swarm

Choose a date suffix (e.g. `20260224` for the date you're applying the update):

```sh
docker -H mega4.build.couchbase.com secret create \
  wildcard_build_couchbase_com_cert_20260224 \
  wildcard.build.couchbase.com.chained.crt

docker -H mega4.build.couchbase.com secret create \
  wildcard_build_couchbase_com_key_20260224 \
  wildcard.build.couchbase.com.key.pem
```

Repeat for `*.couchbase.com` if that cert is also being renewed.

#### 3. Update `traefik.yaml`

Edit the `secrets:` section at the bottom of `traefik.yaml` to point to the new versioned secret names:

```yaml
secrets:
  wildcard_build_couchbase_com_cert:
    external: true
    name: wildcard_build_couchbase_com_cert_20260224   # <-- updated
  wildcard_build_couchbase_com_key:
    external: true
    name: wildcard_build_couchbase_com_key_20260224    # <-- updated
```

#### 4. Update any other stacks that reference the same secrets

Other stacks may also reference the wildcard secrets directly (not via the reverse proxy). Check for and update any references -- for example `builddb_rest/builddb_rest.yaml` has its own `secrets:` block with the same versioned names.

Find all references:

```sh
grep -r 'wildcard_.*_cert_\|wildcard_.*_key_' docker-stacks/
```

#### 5. Redeploy the traefik stack

```sh
./go
```

Or manually:

```sh
docker -H mega4.build.couchbase.com stack deploy --detach=false --with-registry-auth -c traefik.yaml traefik
```

Traefik will pick up the new secrets on redeployment. The rolling update config (`parallelism: 100`) causes all replicas to update simultaneously.

#### 6. Redeploy any other affected stacks

Re-run the deploy command for each stack whose secret references you updated in step 4.

#### 7. Verify

```sh
echo | openssl s_client -connect mega4.build.couchbase.com:443 -servername mega4.build.couchbase.com 2>/dev/null | openssl x509 -noout -dates -subject
```

Confirm the new expiry date and subject match expectations.

#### 8. Clean up old secrets (optional)

Once all stacks are redeployed and verified, remove the old secrets:

```sh
docker -H mega4.build.couchbase.com secret rm wildcard_build_couchbase_com_cert_20260427
```

Old secrets cannot be removed while any service still references them.
