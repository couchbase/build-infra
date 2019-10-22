Some tools for working with Macs.

xcv - a wrapper around github.com/xcpretty/xcode-install, a nice tool
that (mostly) automates installing and managing Xcode versions on a
Mac. The wrapper handles ensuring the right version of ruby is
installed, and installing xcode-install via gem. It will also read
Apple Developer credentials from ~/.ssh/appleid.txt and
~/.ssh/appleid.password.

download_xcode.sh - automatically downloads a given version of Xcode
from Apple's developer site. Since xcv can do this too, this is mostly
useful for archiving .xip downloads Just In Case(tm). I leave it here
as an example of downloading things from developer.apple.com.
