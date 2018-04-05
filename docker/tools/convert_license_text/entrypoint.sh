#!/bin/bash

# If no arguments or /txt doesn't exist, output usage message
if [ ! -d /txt -o $# = 0 ]; then
    cat <<'EOF'

Converts a text file (which may have long text lines) to several forms:

  license.txt - wrapped to 80-column lines (without breaking URLs)
  license.html - formatted as HTML, with certain lines made into headers

In both cases, UTF-8 character sequences (such as double-quotes) will be
replaced with their ASCII equivalents.

The purpose of this container is to automate the conversion of License texts
into the various necessary forms.

Usage:

  docker run --rm -v $(pwd):/txt couchbasebuild/convert_license_text
     <file> [ <output text file> [ <output html file> ] ]

where <file> is a text file in the current directory. The output files will
also be placed in the current directory - don't pass absolute paths. If
output filenames aren't specified, "license.txt" and "license.html" will be
used.

EOF
    exit 1
fi

cd /txt

# Arguments.
i=$1
txt=${2-license.txt}
html=${3-license.html}

# Ok, we're really doing this. First strip UTF-8 stuff.
iconv -f utf-8 -t ascii//TRANSLIT $i > /tmp/ascii.txt

# Produce wrapped output.
fmt /tmp/ascii.txt > $txt

# Tweak to prevent txt2html from scrambling things that look like lists.
perl -pi -e 's/([A-Z1-9])\. /\1FROBOZ /g' /tmp/ascii.txt

# Convert to HTML.
txt2html --titlefirst --outfile $html \
  --custom_heading_regexp 'License Agreement($| for the Java)' \
  --custom_heading_regexp 'SUPPLEMENTAL LICENSE TERMS$' \
  /tmp/ascii.txt

# Un-tweak.
perl -pi -e 's/([A-Z1-9])FROBOZ /\1. /g' $html

# Change owner of output files (don't want them owned by root).
uid=$(stat -c %u .)
gid=$(stat -c %u .)
chown $uid:$gid $txt $html
