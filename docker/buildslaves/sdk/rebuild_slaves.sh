#!/bin/bash -ex

for plat in amzn? centos? debian? ubuntu??
do (
    cd $plat
    ./go --publish
) &
done

wait

echo "All done!"
echo
