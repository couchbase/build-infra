Dockerfiles for specific product builds. Top level is product team
(server, sdk, mobile), second level is specific product, third is
base OS.

There is also "buildjobs" for slaves that are running not for a specific
product. Since these won't (usually?) need to be available for multiple
Linux distributions, the subdirectories should be named for the specific
job or job type.
