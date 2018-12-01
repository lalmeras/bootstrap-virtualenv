#! /bin/bash

# build arrays of packages to install
# can be overloaded by a whitespace-separated environment variable
DEB_PACKAGES=( ${BOOTSTRAP_DEB_PACKAGES:="python-virtualenv libssl-dev python-dev gcc libxml2-dev python-lxml libffi-dev"} )
RPM_PACKAGES=( ${BOOTSTRAP_RPM_PACKAGES:="python2-virtualenv openssl-devel python-devel gcc libxml2-devel python-lxml libffi-devel"} )
TARGET="${BOOTSTRAP_TARGET:=".tools/bootstrap"}"
VIRTUALENV="${BOOTSTRAP_VIRTUALENV:="virtualenv"}"
DEFAULT_REQUIREMENTS=( 'clickable>=0.1.1' 'invoke' )
REQUIREMENTS=( ${BOOTSTRAP_REQUIREMENTS:="${DEFAULT_REQUIREMENTS[@]}"} )
STDIN=${BOOTSTRAP_STDIN:=0}

echo -e "** bootstraping in ${TARGET}"

if [ -n "$BOOTSTRAP_DEBUG" ]; then
    echo "[debug] rpm package: ${RPM_PACKAGES[@]}"
    echo "[debug] deb package: ${DEB_PACKAGES[@]}"
fi

if [ -f /usr/bin/apt-get ]; then
    command=( sudo apt-get install )
    command+=( "${DEB_PACKAGES[@]}" )
elif [ -f /usr/bin/dnf ]; then
    command=( sudo dnf install )
    command+=( "${RPM_PACKAGES[@]}" )
elif [ -f /usr/bin/yum ]; then
    command=( sudo yum install )
    command+=( "${RPM_PACKAGES[@]}" )
fi

if [ -n "${BOOTSTRAP_DEBUG}" ]; then
    echo "[debug] command: ${command[@]}"
fi

echo -e "** perform packages installation"
"${command[@]}"

echo -e "** create bootstrap virtualenv"
if [ -e "${TARGET}" ]; then
    read -u "${STDIN}" -t 1 -n 10000 discard
    read -u "${STDIN}" -p "${TARGET} already exists; do you want to remove it? [y/N]: " -r -n 1 accept
    echo
    if [ "${accept,,}" != "y" ]; then
	echo "** ${TARGET} removal refused"
	echo "** aborting"
	exit 1
    fi
    rm -rf "${TARGET}"
fi

mkdir -p "$( dirname "${TARGET}" )"
venv_command=( "$VIRTUALENV" --python=python2 "${TARGET}" )
if [ -n "${BOOTSTRAP_DEBUG}" ]; then
    echo "[debug] virtualenv command: ${venv_command[@]}"
fi
"${venv_command[@]}"

echo -e "** populate virtualenv"
PIP="${TARGET}/bin/pip"
pip_command=( "$PIP" install "${REQUIREMENTS[@]}" )
if [ -n "${BOOTSTRAP_DEBUG}" ]; then
    echo "[debug] pip command: ${pip_command[@]}"
fi
"${pip_command[@]}"

echo -e "** bootstrap done"
