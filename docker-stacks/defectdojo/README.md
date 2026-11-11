# DefectDojo

DefectDojo deployed as a Docker Swarm stack on `mega4.build.couchbase.com`,
served at https://defectdojo.build.couchbase.com through the traefik
reverse proxy. It holds the govulncheck results uploaded by
`build-tools/defectdojo/import_govulncheck.py`.

- **Stack name:** `defectdojo`
- **Services:** nginx, uwsgi, celerybeat, celeryworker, a one-off
  initializer (database migrations and first-time setup), PostgreSQL and
  Valkey
- **Data:** `/buildteam/defectdojo/{postgres,valkey,media}` on the
  infrastructure node. `/buildteam/defectdojo/mysql` and the other old
  directories are from the 2.x deployment and are no longer used.

## Secrets

All four are external Docker secrets:

- `defectdojo_secret_key`: Django secret key
- `defectdojo_credential_aes_256_key`: encrypts credentials stored in
  DefectDojo
- `defectdojo_database_password_YYYYMMDD`: PostgreSQL password
- `defectdojo_database_url_YYYYMMDD`:
  `postgresql://defectdojo:<password>@postgres:5432/defectdojo`

Swarm secrets can't be changed, so the database secrets have a date
suffix, and `defectdojo.yml` maps them to stable names at the bottom. To
create them (or replace them, with a new date):

```sh
PW=$(openssl rand -base64 24 | tr -d '/+=')
printf %s "$PW" | docker -H mega4.build.couchbase.com secret create \
  defectdojo_database_password_20261113 -
printf %s "postgresql://defectdojo:$PW@postgres:5432/defectdojo" | \
  docker -H mega4.build.couchbase.com secret create \
  defectdojo_database_url_20261113 -
```

Then update the names in `defectdojo.yml`, and keep the password in the
team password store. PostgreSQL only reads the password when it creates
an empty database, so after the first deploy, changing it also needs an
`ALTER USER` inside the database.

## First deploy

1. On the infrastructure node, create the data directories:
   ```sh
   mkdir -p /buildteam/defectdojo/{postgres,valkey,media}
   chown 1000:1000 /buildteam/defectdojo/{postgres,valkey,media}
   ```
2. Deploy: `./go`
3. Wait for the initializer to finish, then get the admin password:
   ```sh
   docker -H mega4.build.couchbase.com service logs defectdojo_initializer | grep "Admin password"
   ```
   The admin user is `build-team@couchbase.com`.

Swarm ignores `depends_on`, so uwsgi may restart a few times until
PostgreSQL is up and the initializer has run the migrations.

## Upgrading

Update the image versions and digests in `env`, check the upgrade notes
at https://docs.defectdojo.com/releases/os_upgrading/ and run `./go`. The
initializer runs any new migrations.
