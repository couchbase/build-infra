# Pathdiff

Pathdiff is intended to provide us with a view of binaries and binary paths for any given version - and changes of those between versions - of a specified product.

It is comprised of a number of different services:

- Frontend: A web UI written using React
- API: A Flask backend which the frontend/automation can communicate with
- Workers: Celery is employed to provide a separation of concerns between worker and API
- Message broker: Redis, used for queueing worker tasks
- Database: MariaDB
