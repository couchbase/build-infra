#!/bin/bash

APPLICATION="${0##*/}"
USAGE="Xcode Command-line Downloader
usage: $APPLICATION [-u AppleID] [-p password] [-x XcodeVersion]

This will pull down an xCode DMG from the Apple Developer site,
which requires authentication.

See http://stackoverflow.com/questions/10335747/how-to-download-xcode-4-5-6-and-get-the-dmg-file

Options:
	-u AppleID        The AppleID that will be used to pull the file
	-p password       The password for the user
	-x xCodeVersion   XCode Version, eg. 11.2, 11.2_beta2

"

error() {
    local ecode="$1"
    shift
    echo "$*" 1>&2
    exit "$ecode"
}

while getopts 'u:x:p:' options; do
	case "$options" in
        u) user_id=${OPTARG};;
		p) password=${OPTARG};;
		x) xcode_version=${OPTARG};;
		\?) error 2 "$USAGE";;
	esac
done

if [[ -z "${user_id}" ]]; then
	if [ -e ~/.ssh/appleid.txt ]; then
        echo "Reading username from ~/.ssh/appleid.txt"
		user_id=$(cat ~/.ssh/appleid.txt)
	else
		error 2 "$USAGE"
	fi
fi

if [[ -z "${password}" ]]; then
	if [ -e ~/.ssh/appleid.password ]; then
		echo "Reading password from ~/.ssh/appleid.password"
		password=$(cat ~/.ssh/appleid.password)
	else
		error 2 "$USAGE"
	fi
fi

if [[ -z "${xcode_version}" ]]; then
	read -p "Enter the Xcode version to retrieve (5.1.1, 6.3) " xcode_version
	if [[ -z "${xcode_version}" ]]; then
		error 2 "$USAGE"
	fi
fi

login_url="https://idmsa.apple.com/IDMSWebAuth/authenticate"
app_entry_url="https://developer.apple.com/services-account/download"
xcode_filename=Xcode_${xcode_version}
xcode_path="/Developer_Tools/${xcode_filename}/${xcode_filename}.xip"
download_url="https://download.developer.apple.com${xcode_path}"

# First need to determine the Application ID, which comes back as part of the response header from this request
echo "Retrieving App ID"
app_id=$(curl -s -i "${app_entry_url}?path=${xcode_path}" | awk -F '[\?\&]' '/appIdKey/ { print $2 };' | sed 's/appIdKey=//')
echo "App ID: <$app_id>"
if [[ ${app_id} ]]; then
	# Now to perform the login and download; POST to the login URL, passing the desired info.
	# Note: --cookie-jar isn't because we want to save the cookies per se; it is just to
	# "enable the cookie engine", per the curl manpage, so that cookies from the first HTTP
	# request will be sent on to later (redirect) HTTP requests.
	echo "Logging in"
	curl -L --cookie-jar cookies -o ${xcode_filename}.xip \
			-d "path=/devcenter/download.action?path%3D${xcode_path}" \
			-d "appIdKey=${app_id}" \
			-d "accNameLocked=false" \
			-d "language=US-EN" \
			-d "Env=PROD" \
			-d "appleId=${user_id}" \
			-d "accountPassword=${password}" \
		"${login_url}"
	rm -f cookies
else
	echo "Error retrieving App ID"
fi

exit 0
