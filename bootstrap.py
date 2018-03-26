#! /bin/env python
# -*- encoding: utf-8 -*-
from __future__ import print_function

import contextlib
import os
import os.path
import shutil
import subprocess
import sys
import tempfile
import os


bootstrap_sh = os.environ['BOOTSTRAP_SH']
bootstrap_requirements = os.environ['BOOTSTRAP_REQUIREMENTS']


def prevent_loop(environ, env_name):
    environ = dict(environ)
    if env_name in environ:
        print('** bootstrap loop detected; bootstrap environment installed but unable to load clickable. Aborting...')
        sys.exit(1)
    environ[env_name] = 'true'
    return environ


clean = '--clean' in sys.argv
bootstrap_phase = 'CLICKABLE_BOOTSTRAP' in os.environ
is_main = __name__ == '__main__'
if is_main or bootstrap_phase:
    # block for ./script.py invocation OR import during bootstrap_phase
    if '--help' in sys.argv or '-h' in sys.argv:
        # print usage
        print("""Usage: {0} [--help|-h] [--clean]
Install a virtualenv with minimal requirements ({1})""".format(__file__, bootstrap_requirements))
        sys.exit(0)
    if is_main and (clean or not os.path.exists(bootstrap_target)):
        # download and run bootstrap.sh on missing target, or explicit clean
        environ = prevent_loop(os.environ, 'BOOTSTRAP_INSTALL')
        environ['BOOTSTRAP_TARGET'] = bootstrap_target
        environ['BOOTSTRAP_REQUIREMENTS'] = bootstrap_requirements
        try:
            import urllib2 as urlreq # Python 2.x
        except:
            import urllib.request as urlreq # Python 3.x
        req = urlreq.Request(bootstrap_sh)
        (fd, script) = tempfile.mkstemp()
        with open(script, 'w') as dest, \
             contextlib.closing(urlreq.urlopen(req)) as src:
            shutil.copyfileobj(src, dest)
        subprocess.check_call(['bash', script], env=environ)
    else:
        try:
            # either pip install or python setup.py handling
            from clickable.bootstrap import run_setup
            run_setup(__file__, name, entry_points=entry_points, callback=bootstrap_done)
            raise Exception('unreachable code')
        except ImportError:
            pass
    # rerun script with venv interpreter after install or import failure
    command = list(sys.argv)
    command.insert(0, os.path.join(bootstrap_target, 'bin/python'))
    '--clean' not in command or command.remove('--clean') # clean must not be looped
    environ = prevent_loop(os.environ, 'BOOTSTRAP_RERUN')
    os.execve(command[0], command, environ)
