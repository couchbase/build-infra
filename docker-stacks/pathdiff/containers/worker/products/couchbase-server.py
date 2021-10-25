import random
import string
import requests
import subprocess

# To help associate our image names with upstream names and package managers
distros = {
    "amzn2": {
        "image": "amazonlinux:2",
        "packager": "yum"
    },
    "centos7": {
        "image": "centos:7",
        "packager": "yum"
    },
    "centos8": {
        "image": "centos:8",
        "packager": "yum"
    },
    "debian9": {
        "image": "debian:9",
        "packager": "apt"
    },
    "debian10": {
        "image": "debian:10",
        "packager": "apt"
    },
    "suse15": {
        "image": "opensuse/leap:15.2",
        "packager": "zypper"
    },
    "ubuntu16.04": {
        "image": "ubuntu:16.04",
        "packager": "apt"
    },
    "ubuntu18.04": {
        "image": "ubuntu:18.04",
        "packager": "apt"
    },
    "ubuntu20.04": {
        "image": "ubuntu:20.04",
        "packager": "apt"
    },
}

# We need to be able to handle pulling released versions from s3
# and unreleased builds from latestbuilds
urls = {
    "apt": {
        "paths": {
            "GA": "https://packages.couchbase.com/releases/__VERSION__/",
            "unreleased": "http://latestbuilds.service.couchbase.com/builds/latestbuilds/__PRODUCT__/zz-versions/__VERSION__/__BUILD__/"
        },
        "files": {
            "GA": "__PRODUCT__-__EDITION_____VERSION__-__DISTRO___amd64.deb",
            "unreleased": "__PRODUCT__-__EDITION_____VERSION__-__BUILD__-__DISTRO___amd64.deb"
        }
    },
    "yum": {
        "paths": {
            "GA": "https://packages.couchbase.com/releases/__VERSION__/",
            "unreleased": "http://latestbuilds.service.couchbase.com/builds/latestbuilds/__PRODUCT__/zz-versions/__VERSION__/__BUILD__/"
        },
        "files": {
            "GA": "__PRODUCT__-__EDITION__-__VERSION__-__DISTRO__.x86_64.rpm",
            "unreleased": "__PRODUCT__-__EDITION__-__VERSION__-__BUILD__-__DISTRO__.x86_64.rpm"
        }
    },
    "zypper": {
        "paths": {
            "GA": "https://packages.couchbase.com/releases/__VERSION__/",
            "unreleased": "http://latestbuilds.service.couchbase.com/builds/latestbuilds/__PRODUCT__/zz-versions/__VERSION__/__BUILD__/"
        },
        "files": {
            "GA": "__PRODUCT__-__EDITION__-__VERSION__-__DISTRO__.x86_64.rpm",
            "unreleased": "__PRODUCT__-__EDITION__-__VERSION__-__BUILD__-__DISTRO__.x86_64.rpm"
        }
    }
}

# Packagers and check_file_list contain the steps required to retrieve
# a list of executables in a given package - this is what we'll run in
# our containers
packagers = {
    "apt": [
        f'apt-get update &>/dev/null',
        f'apt-get install -y curl file &>/dev/null',
        f'curl -LsfO __URL__',
        f'apt install -y ./__PACKAGE__ &>/dev/null',
        f'flist=`dpkg -L __PRODUCT__ || dpkg -L __PRODUCT__-__EDITION__`',
    ],
    "yum": [
        f'echo "0 string \\#\\!" >> /etc/magic',
        f'yum install -y yum-utils file &>/dev/null',
        f'yum install -y __URL__ &>/dev/null ; flist=`repoquery --installed -l "__PRODUCT__*" 2>/dev/null`',
    ],
    "zypper": [
        f'echo "0 string \\#\\!" >> /etc/magic',
        f'zypper install -y file &>/dev/null',
        f'zypper --no-gpg-checks install -y __URL__ &>/dev/null ; flist=`rpm -ql __PRODUCT__ || rpm -ql __PRODUCT__-__EDITION__`',
    ]
}
check_file_list = 'for f in $flist; do if [[ -x "$f" && -f "$f" ]]; then if file --mime "$f" | awk "{print \$2}" | grep -E "^(shebang|application)" &>/dev/null; then echo $f; fi; fi; done'


class Docker():
    def __init__(self, distro=None, product=None, edition=None, version=None, build=None):
        if distro not in distros.keys():
            raise KeyError(f"{distro} not found in distros")
        self.distro = distro
        self.build = build
        self.product = product
        self.edition = edition
        self.version = version
        self.packager = distros[self.distro]['packager']
        status = "GA" if build == "GA" else 'unreleased'
        path = urls[self.packager.split(":")[0]]['paths'][status]
        file = urls[self.packager.split(":")[0]]['files'][status]
        self.url = ((path+file).replace("__PACKAGE__", file)
                    .replace("__PRODUCT__", self.product)
                    .replace("__VERSION__", self.version)
                    .replace("__DISTRO__", self.distro)
                    .replace("__EDITION__", self.edition)
                    .replace("__BUILD__", build))

        self.runcmd = "&&".join([line
                                 .replace("__URL__", self.url)
                                 .replace("__PACKAGE__", file)
                                 .replace("__PRODUCT__", self.product)
                                 .replace("__VERSION__", self.version)
                                 .replace("__DISTRO__", self.distro)
                                 .replace("__EDITION__", self.edition)
                                 .replace("__BUILD__", build)
                                 for line in packagers[self.packager]]) + "&&" + check_file_list
        self.pull()

    def url_ok(self):
        r = requests.head(self.url)
        return r.status_code == requests.codes.ok

    def pull(self):
        runcmd = ["docker", "pull", distros[self.distro]['image']]
        proc = subprocess.Popen(runcmd, stdout=subprocess.PIPE)
        proc.communicate()

    def run(self):
        if not self.url_ok():
            raise RuntimeError("Package does not exist")
        random_str = ''.join(random.choice(string.ascii_letters)
                             for i in range(4))
        runcmd = [
            "docker", "run", "--rm",
            "--name", f"{self.product}-{self.distro}-{self.edition}-{self.version}-{self.build}_{random_str}",
            "-i", distros[self.distro]['image'],
            "bash", "-c", self.runcmd
        ]
        proc = subprocess.Popen(runcmd, stdout=subprocess.PIPE)
        streamdata = proc.communicate()[0]
        if proc.returncode == 0:
            self.binary_files = list(
                filter(None, streamdata.decode("utf-8").strip().split("\n")))
        else:
            raise RuntimeError("Failed to read file list")
