Autoswitch Python micromamba
============================

|TravisCI| |Release| |GPLv3|

*zsh-autoswitch-micromamba* is a simple ZSH plugin (which is modified from `zsh-autoswitch-micromamba <https://github.com/bckim92/zsh-autoswitch-micromamba>`)
that switches micromamba environments automatically as you move between directories.

* `How it Works`_
* `More Details`_
* Installing_
* Setup_
* Commands_
* Options_
* `Security Warnings`_


How it Works
------------

Simply call the ``mkmenv`` command in the directory you wish to setup a
micromamba environment. A micromamba environment specific to that folder will
now activate every time you enter it.

See the *Commands* section below for more detail.

More Details
------------

Moving out of the directory will automatically deactivate the micromamba
environment. However you can also switch to a default python micromamba
environment instead by setting the ``AUTOSWITCH_DEFAULT_MICROMAMBAENV`` environment
variable.

Internally this plugin simply works by creating a file named ``.menv``
which contains the name of the micromamba environment created (which is the
same name as the current directory but can be edited if needed). There
is then a precommand hook that looks for a ``.menv`` file and switches
to the name specified if one is found.

**NOTE**: you may want to add ``.menv`` to your ``.gitignore`` in git
projects (or equivalent file for the Version Control you are using).

Installing
----------

Add one of the following lines to your ``.zshrc`` file depending on the
package manager you are using:

ZPlug_

::

    zplug "zohebjamal/zsh-autoswitch-micromamba"

Antigen_

::

    antigen bundle "zohebjamal/zsh-autoswitch-micromamba"

Zgen_

::

    zgen load "zohebjamal/zsh-autoswitch-micromamba"

Setup
-----

``micromamba`` must be installed for this plugin to work correctly.
You can find installation instructions from `official mamba user guide <https://mamba.readthedocs.io/en/latest/installation.html>`__.


Commands
--------

mkmenv
''''''

Setup a new project with micromamba envirionment autoswitching using the ``mkmenv``
helper command.

::

    $ cd my-python-project
    $ mkmenv
    Solving environment: done
    ## Package Plan ##
    environment location: /home/<name>/.micromamba/envs/my-python-project
    added / updated specs:
      - python=3.5
    The following NEW packages will be INSTALLED:
        ca-certificates: 2018.03.07-0
        certifi:         2018.4.16-py35_0
        libedit:         3.1.20170329-h6b74fdf_2
        libffi:          3.2.1-hd88cf55_4
        libgcc-ng:       7.2.0-hdf63c60_3
        libstdcxx-ng:    7.2.0-hdf63c60_3
        ncurses:         6.1-hf484d3e_0
        openssl:         1.0.2o-h20670df_0
        pip:             10.0.1-py35_0
        python:          3.5.5-hc3d631a_4
        readline:        7.0-ha6073c6_4
        setuptools:      39.2.0-py35_0
        sqlite:          3.24.0-h84994c4_0
        tk:              8.6.7-hc745277_3
        wheel:           0.31.1-py35_0
        xz:              5.2.4-h14c3975_4
        zlib:            1.2.11-ha838bed_2
    Proceed ([y]/n)?

Optionally, you can specify the python binary to use for this micromamba environment

::

    $ mkmenv python=3.5

In fact, ``mkmenv`` supports any parameters that can be passed to ``micromamba create``

``mkmenv`` will create a micromamba environment with the same name as the
current directory, suggest installing ``requirements.txt`` if available
and create the relevant ``.menv`` file for you.

Next time you switch to that folder, you'll see the following message

::

    $ cd my-python-project
    Switching micromamba environment: my-python-project  [Python 3.5.5 :: Anamicromamba, Inc.]
    $

If you have set the ``AUTOSWITCH_DEFAULT_MICROMAMBAENV`` environment variable,
exiting that directory will switch back to the value set.

::

    $ cd ..
    Switching micromamba environment: mydefaultenv 
    $

Otherwise, ``micromamba deactivate`` will simply be called on the micromamba to
switch back to the global python environment.

Autoswitching is smart enough to detect that you have traversed to a
project subdirectory. So your micromamba environment will not be deactivated if you
enter a subdirectory.

::

    $ cd my-python-project
    Switching micromamba environment: my-python-project  [Python 3.4.3+]
    $ cd src
    $ # Notice how this has not deactivated the project micromamba environment
    $ cd ../..
    Switching micromamba environment: mydefaultenv  [Python 3.4.3+]
    $ # exited the project parent folder, so the micromamba environment is now deactivated

rmmenv
''''''

You can remove the micromamba environment for a directory you are currently
in using the ``rmmenv`` helper function:

::

    $ cd my-python-project
    $ rmmenv
    Switching micromamba environment: mydefaultenv  [Python 2.7.12]
    Removing myproject...

This will delete the micromamba environment in ``.menv`` and remove the
``.menv`` file itself. The ``rmmenv`` command will fail if there is no
``.menv`` file in the current directory:

::

    $ cd my-non-python-project
    $ rmmenv
    No .menv file in the current directory!

Options
-------

**Setting a default micromamba environment**

If you want to set a default micromamba environment then you can also
export ``AUTOSWITCH_DEFAULT_MICROMAMBAENV`` in your ``.zshrc`` file.

::

    export AUTOSWITCH_DEFAULT_MICROMAMBAENV="mydefaultenv"
    antigen bundle bckim92/zsh-autoswitch-micromamba

**Set verbosity when changing environments**

You can prevent verbose messages from being displayed when moving
between directories. You can do this by setting ``AUTOSWITCH_SILENT`` to
a non-empty value.

Security Warnings
-----------------

zsh-autoswitch-micromamba will warn you and refuse to activate a micromamba
envionrment automatically in the following situations:

-  You are not the owner of the ``.menv`` file found in a directory.
-  The ``.menv`` file has weak permissions. I.e. it is readable or
   writable by other users on the system.

In both cases, the warnings should explain how to fix the problem.

These are security measures that prevents other, potentially malicious
users, from switching you to a micromamba environment you did not want to
switch to.


.. |TravisCI| image:: https://travis-ci.org/MichaelAquilina/zsh-autoswitch-virtualenv.svg?branch=master
   :target: https://travis-ci.org/MichaelAquilina/zsh-autoswitch-virtualenv

.. |Release| image:: https://badge.fury.io/gh/MichaelAquilina%2Fzsh-autoswitch-virtualenv.svg
    :target: https://badge.fury.io/gh/MichaelAquilina%2Fzsh-autoswitch-virtualenv

.. |GPLv3| image:: https://img.shields.io/badge/License-GPL%20v3-blue.svg
   :target: https://www.gnu.org/licenses/gpl-3.0


