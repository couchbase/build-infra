#!/bin/bash -ex

for plat in alpine amzn? centos? debian? ubuntu??
do (
    cd $plat
    ./go --publish
) &
done

wait

echo "All done!"
echo
