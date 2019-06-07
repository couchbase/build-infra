#!/bin/bash

# If no arguments or /txt doesn't exist, output usage message
if [ ! -d /txt -o $# = 0 ]; then
    cat <<'EOF'

Converts a text file (which may have long text lines) to several forms:

  license.txt - wrapped to 80-column lines (without breaking URLs)
  license-long-lines.txt - same formatting as input except for UTF-8 removal
  license.html - formatted as HTML, with certain lines made into headers

In all cases, UTF-8 character sequences (such as double-quotes) will be
replaced with their ASCII equivalents.

The purpose of this container is to automate the conversion of License texts
into the various necessary forms.

Usage:

  docker run --rm -v $(pwd):/txt couchbasebuild/convert_license_text
     <input file> [ <text file> [ <long-line text file [ <html file> ] ] ]

where <input file> is a text file in the current directory. The output files will
also be placed in the current directory - don't pass absolute paths. If
output filenames aren't specified, "license.txt", "license-long-lines.txt", and
"license.html" will be used.

HINTS:

 - Ensure the input document has no trailing whitespace on lines.
 - Ensure consistent formatting throughout input document; eg. all sections
   should start with "XX. Section Title" and a newline before section body.

EOF
    exit 1
fi

cd /txt

# Arguments.
i=$1
txt=${2-license.txt}
longtxt=${3-license-long-lines.txt}
html=${4-license.html}

tmpfile=/tmp/ascii.txt

# Ok, we're really doing this. First strip UTF-8 stuff.
iconv -f utf-8 -t ascii//TRANSLIT $i > ${tmpfile}

# Produce wrapped output. Use --split-only to honor newlines in source.
fmt --split-only ${tmpfile} > ${txt}

# Produce unwrapped output - just the de-UTF-8'd file.
cp ${tmpfile} ${longtxt}

# Tweak to prevent txt2html from scrambling things that look like lists.
perl -pi -e 's/([A-Z1-9])\. /\1FROBOZ /g' ${tmpfile}

# Convert to HTML.
txt2html --titlefirst --outfile $html \
  --custom_heading_regexp 'License Agreement($| for the Java)' \
  --custom_heading_regexp 'SUPPLEMENTAL LICENSE TERMS$' \
  ${tmpfile}

# Un-tweak.
perl -pi -e 's/([A-Z1-9])FROBOZ /\1. /g' ${html}

# Change owner of output files (don't want them owned by root).
uid=$(stat -c %u .)
gid=$(stat -c %u .)
chown $uid:$gid ${txt} ${longtxt} ${html}
