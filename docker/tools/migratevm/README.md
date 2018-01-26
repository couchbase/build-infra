Based on https://github.com/djamps/migrate-vm

```
Usage: docker run --rm -it couchbasebuild/migrate-vm
  --shost <source XenServer IP>
  --suser <username on source, usually root>
  --spass <password for suser>
  --svm <name of VM on source XenServer>
  --dhost <destination XenServer IP>
  --duser <username on destination, usually root>
  --dpass <password for duser>
  --dsr <storage repository on destination, usualy "" for default>
```

Any of the above arguments can be omitted and the tool will prompt you for them.
