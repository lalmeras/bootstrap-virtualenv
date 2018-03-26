#! /bin/bash
set -e

# build arrays of packages to install
# can be overloaded by a whitespace-separated environment variable
DEB_PACKAGES=( ${BOOTSTRAP_DEB_PACKAGES:="python-virtualenv libssl-dev python-dev gcc libxml2-dev python-lxml libffi-dev"} )
RPM_PACKAGES=( ${BOOTSTRAP_RPM_PACKAGES:="python2-virtualenv openssl-devel python-devel gcc libxml2-devel python-lxml libffi-devel"} )
TARGET="${BOOTSTRAP_TARGET:=".tools/bootstrap"}"
VIRTUALENV="${BOOTSTRAP_VIRTUALENV:="virtualenv"}"
DEFAULT_REQUIREMENTS=( )
REQUIREMENTS=( ${BOOTSTRAP_REQUIREMENTS:="${DEFAULT_REQUIREMENTS[@]}"} )
STDIN=${BOOTSTRAP_STDIN:=0}

done=
while [ $# -gt 0 -a -z "$done" ]; do
    case "$1" in
        "--clean")
            clean=true
            shift
            ;;
        "--skip-packages")
            skip_packages=true
            shift
            ;;
        "*")
            done=true
            ;;
    esac
done

if [ -z "$skip_packages" ]; then
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
else
    echo -e "** skip packages installation"
fi

echo -e "** bootstraping in ${TARGET}"

if [ -x "$TARGET/bin/python" -a -z "$clean" ]; then
    echo -e "** skipping requirements as ${TARGET} exists; use --clean to force reinstall"
else
    echo -e "** create bootstrap virtualenv"
    if [ -e "${TARGET}" ]; then
        read -u "${STDIN}" -t 1 -n 10000 discard || true
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
    venv_command=( "$VIRTUALENV" "${TARGET}" )
    if [ -n "${BOOTSTRAP_DEBUG}" ]; then
        echo "[debug] virtualenv command: ${venv_command[@]}"
    fi
    "${venv_command[@]}"

    echo -e "** populate virtualenv"
    PIP="${TARGET}/bin/pip"
    if [ "${#REQUIREMENTS[@]}" -ne 0 ]; then
        pip_command=( "$PIP" install "${REQUIREMENTS[@]}" )
        if [ -n "${BOOTSTRAP_DEBUG}" ]; then
            echo "[debug] pip command: ${pip_command[@]}"
        fi
        "${pip_command[@]}"
    fi
    if [ -f "setup.py" ]; then
        "${TARGET}/bin/python" setup.py --pip-requirements | xargs --null \
            "$PIP" install
        "$PIP" install -e"$( dirname $( readlink -f "setup.py" ) )"
    fi
fi
echo -e "** bootstrap done"

# if [ -n "$BOOTSTRAP_COMMAND" ]; then
#     echo -e "** launch ${BOOTSTRAP_COMMAND} ${@}"
#     source "${TARGET}/bin/activate"
#     # invoke with remaining args
#     "$BOOTSTRAP_COMMAND" "${@}"
# fi
