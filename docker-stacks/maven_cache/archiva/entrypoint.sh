#!/usr/bin/env bash

# We track whether the service is available before creating the admin user
# iterations are tracked and execution fails once an upper bound is reached
started=false
iteration=0
max_iterations=10

# Any problems encountered during startup get logged to a `failures` string
# if this string is non-null at the end of execution, we output it and fail out
failures=""

# Admin password is stored in a swarm secret
admin_password=$(cat /run/secrets/archiva_password)

if [ "$admin_password" = "" ]; then failures="${failures}    admin_password not found\n"; fi
if [ "$admin_email" = "" ]; then failures="${failures}    admin_email not specified\n"; fi

# ${ARCHIVA_BASE} is a volume mountpoint, we need to make sure certain subdirs
# exist, and seed initial content if required
mkdir -p ${ARCHIVA_BASE}/{logs,data,temp,conf}
rsync --recursive --ignore-existing /app/conf/* ${ARCHIVA_BASE}/conf

# We also need to make sure the user running the app owns this content
chown -R archiva:archiva ${ARCHIVA_BASE}

# The app is backgrounded so we can monitor its startup and create the admin user
su archiva -c '/app/bin/archiva console &'

while [ "$started" != true -a $iteration -lt $max_iterations ]
do
    sleep 10
    curl --fail --silent --output /dev/null http://localhost:8080 && started=true || echo "WARN: archiva still starting"
    iteration=$(($iteration+1))
done

if [ $iteration = $max_iterations ]
then
    failures="${failures}    could not connect to archiva\n"
fi

# If we got here without logging any failures, we know the service is alive
# and we have all the information required to create the admin user
if [ "$failures" == "" ]
then
    echo "INFO: archiva online, creating admin user"
    curl \
        http://localhost:8080/restServices/redbackServices/userService/createAdminUser \
        --header "Referer: http://localhost:8080" \
        --header "Content-Type: application/json; charset=utf-8" \
        --fail \
        --data-binary @- <<EOF &>/dev/null || failures="$failures    unable to create admin user"
{
    "username":"admin",
    "password":"${admin_password}",
    "confirmPassword":"${admin_password}",
    "fullName":"Administrator",
    "email":"${admin_email}",
    "validated":true,
    "assignedRoles":[],
    "modified":true,
    "rememberme":false,
    "logged":false
}
EOF
fi

if [ "$failures" != "" ]
then
    cat ${ARCHIVA_BASE}/logs/re*
    printf "\n\nFailed to start:\n$failures"
    exit 1
fi

sleep 5

# Stream logs (since we pushed the app into the background to add the user)
su archiva -c "tail -f ${ARCHIVA_BASE}/logs/archiva.log"
