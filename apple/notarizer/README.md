# Notarizer

This script acts as a REST endpoint to which you can post an archive, and receive a gatekeeper-friendly, signed and notarized archive in response.

The service:
  - receives an archive + some metadata via multipart POST
  - signs binaries inside targeted directories
  - signs the archive
  - (optionally) notarizes the archive
  - returns the archive to the requester

### Resources:

  |Verb|Resource|Function|
  |---|---|---|
  |POST|/zip/[name]|sign and optionally notarize files|
  |GET|/log/[bundle]|retrieve session logs|

### Fields:
  /zip/[name]
    binary_locations  pipe-seperated list of locations in which to sign binaries (e.g. bin|bar)
    bundle            the reverse-DNS bundle-id to pass to the Apple notarization service, also used when retrieving logs (e.g. com.couchbase.couchbase-server)
    content           archive content to process (e.g. @myfile.zip)
    notarize          boolean indicating whether the archive should be notarized after binaries are signed
    token             authentication token

  /log/[bundle]
    none
