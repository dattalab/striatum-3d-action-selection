Usage
=====

.. warning:: Many functions in this toolbox are parallel-enabled (i.e. include parfor loops), check the Parallel Preferences in your MATLAB installation to avoid unwanted behavior.

This codebase allows you to work with data collecting using the Kinect2 (or Kinect for Xbox One) sensor.  The typical workflow is:

1. Extract raw data (crop and orient mouse)
2. Aggregate extractions from multiple sessions
3. Compute principal components from the cropped, oriented mice
4. Model the data
5. Collect output from the model

.. _organization:

How to organize your data
-------------------------

Typically, you want to keep all data in a related experiment that you might model together in the *same* directory.  Here's a truncated list of a directory structure I used for a recent experiment.  (Note that data from extractions is also shown, for now you should only have ``depth.dat``, ``depth_ts.txt``, and ``metadata.json``, or a tarball ``*.tar.gz``).

::

  my_project
  ├── session_20170609165919
  │   ├── depth.dat
  │   ├── depth_ts.txt
  │   ├── kinect_object.mat
  │   ├── metadata.json
  │   ├── proc
  │   │   ├── depth_bounded.mat
  │   │   ├── depth_bounded.mp4
  │   │   ├── depth_bounded_rotated.mat
  │   │   ├── depth_bounded_rotated.mp4
  │   │   ├── depth_masked.mat
  │   │   ├── depth_masked.mp4
  │   │   ├── depth_stats.mat
  │   │   └── depth_stats.mp4
  │   ├── roi_debug_dist.tiff
  │   ├── roi_debug_siz.tiff
  │   ├── roi_debug_sol.tiff
  │   ├── roi_extraction.tiff
  │   ├── roi_firstframe.tiff
  │   ├── roi.mat
  │   └── roi_tracking.tiff
  ├── session_20170609170129
  │   ├── depth.dat
  │   ├── depth_ts.txt
  │   ├── kinect_object.mat
  │   ├── metadata.json
  │   ├── proc
  │   │   ├── depth_bounded.mat
  │   │   ├── depth_bounded.mp4
  │   │   ├── depth_bounded_rotated.mat
  │   │   ├── depth_bounded_rotated.mp4
  │   │   ├── depth_masked.mat
  │   │   ├── depth_masked.mp4
  │   │   ├── depth_stats.mat
  │   │   └── depth_stats.mp4
  │   ├── roi_debug_dist.tiff
  │   ├── roi_debug_siz.tiff
  │   ├── roi_debug_sol.tiff
  │   ├── roi_extraction.tiff
  │   ├── roi_firstframe.tiff
  │   ├── roi.mat
  │   └── roi_tracking.tiff
  ├── session_20170609174946
  │   ├── depth.dat
  │   ├── depth_ts.txt
  │   ├── kinect_object.mat
  │   ├── metadata.json
  │   ├── proc
  │   │   ├── depth_bounded.mat
  │   │   ├── depth_bounded.mp4
  │   │   ├── depth_bounded_rotated.mat
  │   │   ├── depth_bounded_rotated.mp4
  │   │   ├── depth_masked.mat
  │   │   ├── depth_masked.mp4
  │   │   ├── depth_stats.mat
  │   │   └── depth_stats.mp4
  │   ├── roi_debug_dist.tiff
  │   ├── roi_debug_siz.tiff
  │   ├── roi_debug_sol.tiff
  │   ├── roi_extraction.tiff
  │   ├── roi_firstframe.tiff
  │   ├── roi.mat
  │   └── roi_tracking.tiff
  ├── session_20170609175249
  │   ├── depth.dat
  │   ├── depth_ts.txt
  │   ├── kinect_object.mat
  │   ├── metadata.json
  │   ├── proc
  │   │   ├── depth_bounded.mat
  │   │   ├── depth_bounded.mp4
  │   │   ├── depth_bounded_rotated.mat
  │   │   ├── depth_bounded_rotated.mp4
  │   │   ├── depth_masked.mat
  │   │   ├── depth_masked.mp4
  │   │   ├── depth_stats.mat
  │   │   └── depth_stats.mp4
  │   ├── roi_debug_dist.tiff
  │   ├── roi_debug_siz.tiff
  │   ├── roi_debug_sol.tiff
  │   ├── roi_extraction.tiff
  │   ├── roi_firstframe.tiff
  │   ├── roi.mat
  │   └── roi_tracking.tiff


Extracting data (bash)
----------------------

Say we have a tarball created by an acquisition GUI, ``session_20171202greatdata.tar.gz``, and we have already installed the repo per the :ref:`Installation instructions <installation>`.  If you want to extract some data from the command line on o2, use the following command

.. code-block:: bash

  cd ~/place_where_i_keep_data
  kinect_extract_it  -i session_20171202greatdata.tar.gz

To see all of the options available for the script, and typically usage patterns, run without any options or arguments.

.. code-block:: bash

  kinect_extract_it

Extracting data (MATLAB)
------------------------

You may also, for a variety of reasons, want to extract from MATLAB.  To do so, enter a MATLAB session navigate to either a tarball or directory with some raw data, then:

.. code-block:: matlab

  cd ~/place_where_i_keep_data
  kinect_extract_it('datafile.tar.gz',true)

The second argument specifies that the data has a cable.  To see all options for the script:

.. code-block:: matlab

  help kinect_extract_it;

Hopefully you see a...helpful help dialogue.

Interacting with extracted data
-------------------------------

After an extraction has completed, you should see a directory ``proc`` as a sub-directory in the extracted tarball or directory.  Now we can make a ``kinect-extract`` object from the data.

.. code-block:: matlab

  cd ~/place_with_data/session_2018021200000/
  ext=kinect_extract;

Now there an object stored in the variable `ext`.  A few useful methods to know, first:


.. code-block:: matlab

  raw_frames=ext.load_oriented_frames('raw'); % loads extracted frames
  figure();
  imagesc(raw_frames(:,:,1)) % display the first frame

What if we want to compute some scalars?  If your data has no cables ``ext.has_cable=false``, then, go ahead and compute some scalars. Otherwise, you must have computed both principal components and principal component scores first (see sections below), since they are used to denoise the mouse.

.. code-block:: matlab

  ext.compute_scalars; % compute scalars
  figure();
  plot(ext.projections.velocity_mag) % display velocity

This will make a plot of 2d velocity (in pixels).  We can also compute principal components to use for modeling.

.. code-block:: matlab

  ext.compute_pcs; % compute principal components
  ext.apply_pcs; % apply pcs to compute pc scores
  figure();
  plot(ext.projections.pca(:,1)) % plot the first principal component score

  figure():
  ext.pca.eigenmontage % look at the components

Note that all quantities in ``ext.projections`` will drop in ``nans`` for dropped frames, so that the timebase is uniform.  In other words, if the camera drops 30 frames in the middle of a recording session, 30 ``nans`` will be dropped in at that point.  If you want to get a quantity back into the original frame timebase (i.e. with no ``nans``), use the ``get_original_timebase`` method.

.. code-block:: matlab

  original_vel_mag=ext.get_original_timebase(ext.projections.velocity_mag); % get 2d velocity in units of frames

Now, if we want to save our progress.

.. code-block:: matlab

  ext.save_progress;

This will save our object in the data directory automatically as ``kinect_object.mat``.

Aggregating sessions
--------------------

Since ``kinect-extract`` is a class, we can create an object array, with one object per extracted session.  If you were using the directory structure :ref:`listed here <organization>`. You would navigate to ``my_projection``, then from MATLAB issue the following command:

.. code-block:: matlab

  objs=kinect_extract_find_all_objects(pwd,true);

This will find all extracted directories in the current directory (the second argument tells the script to make objects where they don't already exist). So then we can compute PCs and scalars using *all* of the objects in the array.

.. code-block:: matlab

  objs.compute_all_projections;


Computing principal components and scalars (bash)
-------------------------------------------------

Since this is a common step, there is a bash script for computing all pcs and scalars for all extracted data recursively found in a given directory. Assuming you have installed the bash scripts as prescribed :ref:`here <installation>`.  Note that by default it is assumed that you are running this on an o2 node (login or compute node).

.. code-block:: bash

  cd ~/dir_with_lots_of_extractions
  kinect_extract_get_projections -i $pwd


To see how the script is normally used, run without any options.

.. code-block:: bash

  kinect_extract_get_projections


Computing principal components (MATLAB)
---------------------------------------

The simplest way to compute principal components within a MATLAB session, along with all scalars and projections, is to use the ``compute_all_projections`` method.

.. code-block:: matlab

  obj.compute_all_projections


Making a flip classifier
------------------------

If you find that your data has lots of flips, you'll need to make a flip classifier. The first thing you'll want to do here is correct any flips in your data.  If you have one object you want to correct, then run:

.. code-block:: matlab

  obj.flip_tool;

You should now see a GUI for marking flips.  Mark every time the mouse flips (from left to right *and* right to left).  Be sure to click *save* before you close the window.  A text file with the frame numbers of flips should now be in the ``proc`` sub-directory.

.. code-block:: matlab

  obj.set_option('flip','method','f')
  obj.correct_flips(true);

This sets the flip correction option to (f)ile, and then corrects flips, forcing a correction even if we already have run a flip classifier on the data.

Exporting data for modeling
---------------------------

If we want to export our pcs for modeling, we can use the ``export_projection_to_cell`` method.

.. code-block:: matlab

  ext.export_projection_to_cell('pca','firstattempt')

You should now see a file in the ``_analysis`` sub-directory, ``export_firstattempt.mat``, which has a cell array ``features``, containing your principal component scores.  This can be used for modeling.

Similarly, if we use the same export method on an *object array*, this will now export all objects, where each object's projections are an element in a cell array (i.e. object 1 in the array maps to ``features{1}``).

.. code-block:: matlab

  objs=kinect_extract_findall_objects;
  objs.export_projection_to_cell('pca','myfirstgroupexport')

Assigning groups to objects
---------------------------

We may want to group the data in an intelligent way, e.g. we have two treatment groups.  If you know which objects correspond to which group, then

.. code-block:: matlab

  for i in length(indices_in_group_1)
    obj(indices_in_group_1(i)).set_group('Group1');

  for i in length(indices_in_group2)
    obj(indices_in_group2(i)).set_group('Group2');

These objects are now assigned to these groups, to retrieve the groups associated with your object array then:

.. code-block:: matlab

  groups=obj.get_groups;

If you export the data again, an additional variable ``groups`` will be exported as well, which will be useful for grouping data for modeling.

Custom options
--------------

Under construction...
