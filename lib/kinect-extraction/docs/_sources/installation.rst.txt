.. _installation:

Installation
=============

Note that this assumes a passing familiarity with the command line and git.  If you are unfamiliar, google "command line tutorial" and "git tutorial" (hard-linking to specific tutorials would be a fool's errand at this point).

Simply clone the kinect-extract github repository, and add the directory and subdirectories to your MATLAB path. More details below.

Requirements
------------

This has been tested using MATLAB 2016A and later on Mac and CentOS. The only MATLAB Toolboxes required are the Signal Processing, Statistics, and Image Processing toolboxes (AFAIK), which are included in most standard installations.  It is highly recommended that you have git installed for ease of installation and managing updates.

Manual installation
-------------------

First clone the repository somewhere reasonable using the terminal (Linux/OS X).

.. code-block:: bash

	git clone https://github.com/jmarkow/kinect-extract.git

Next, make sure the repository and all subdirectories (excluding docs are included in your MATLAB path).  Finally, there are convenience bash scripts that you may want to take advantage of in ``kinect-extract/bash``.  It is recommended to create symlinks in ``/usr/local/bin``.

.. code-block:: bash

  mkdir /usr/local/bin
  ln -s ~/kinect-extract/bash/kinect_extract_it.sh /usr/local/bin/kinect_extract_it
  ln -s ~/kinect-extract/bash/kinect_extract_get_projections.sh /usr/local/bin/kinect_extract_it

o2
-------------------

So this is annoying, but you only need to do it once. To ensure that your MATLAB path is set correctly on o2, run the following after downloading the repo into a sensible location on o2.  Fire up an interactive MATLAB session, then:

.. code-block:: matlab

  mkdir('~/Documents/MATLAB')
  addpath('location_of_kinect-extract')
  savepath('~/Documents/MATLAB/pathdef.m')
  userpath('~/Documents/MATLAB')
  savepath

Finally create a file named ```startup.m`` in ``~/Documents/MATLAB``, with the following contents:

.. code-block:: matlab

  path(pathdef)

To test that everything is working close out MATLAB, start a new sesssion, and try this:

.. code-block:: matlab

  help kinect_extract_find_all_objects;
