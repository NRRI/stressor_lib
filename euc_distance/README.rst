Euclidean distance
==================

Code to calculate "Euclidean distance" landscape stress integration
metric.  

For distinct spatial units such as watersheds "stress" levels such as percent
agricultural land cover, percent developed land cover, road density
(km / km:super:2), and population density (people / km:super:2) are determined
using GIS techniques such as "Zonal Statistics".

Prior to following the steps, a correction may be applied for
small watersheds classed as 100% agricultural land cover which also
include roads.  The need and procedure for this correction
is explained below, it is not part of the core Euclidean distance
metric.

Exampled data (in ``example_data.csv``)::

    wshed, pcntag, pcntdev, roadden, pop,   area
     1001,     22,       7,    1.11, 423, 342621
     1002,    100,       0,     0.2,  12,   4244
     1003,      7,      45,     2.3, 677,  43632
     1010,     18,      22,     0.8, 314, 163217

Normalized (rescaled zero to one) values::

   wshed pcntag_nrm pcntdev_nrm roadden_nrm pop_nrm
    1001      0.161       0.156       0.433   0.618
    1002      1.000       0.000       0.000   0.000
    1003      0.000       1.000       1.000   1.000
    1010      0.118       0.489       0.286   0.454


#. Each stressor ``x`` is rescaled zero to one::

       x_nrm = (x - min(all-x)) / (max(all-x) - min(all-x))

#. Stressors are divided into two categories, "development", and
   "agricultural".
    
#. Within each category, the `MaxRel` value is determined, this is
   the maximum value of the rescaled stressors for that watershed.
   In the example data there's only one stressor in the agricultural
   category, so ``ag_mxr`` is the same as ``pcntag_nrm``, the
   rescaled percent agricultural land cover stressor.  For the
   development category, ``dev_mxr`` is 0.618, 0.0, 1.000, and 0.489
   for the four watersheds, respectively.
   
#. An intermediate value `s` is calculated as::

       s = sqrt(ag_mxr*ag_mxr + dev_mxr*dev_mxr)

#. ``s`` is rescaled zero to one, as before, to give the `Euclidean
   distance metric` for the data set.

A variable set in the configuration file, ``d_ignore``, can be used to exclude some
records from the calculation of ``min(all-x)`` and ``max(all-x)``.  This allows,
for example, preventing extremely small watersheds determining the top quarter
of a stressors range due to processing artifacts in rasterization when dealing
with polygons only 10-20 grid cells in area.

Files created
-------------

If invoked as::

    R --no-save -f calc_ED.R --args myProject.R

where ``myProject.R`` is the configuration files based on
``example_config.R``, ``calc_ED.R`` will create the following
files:

myProject.ed.csv
    Results in CSV
myProject.ed.dbf
    Results in DBF
myProject.ed.minmax.R
    Minimum and maximum values used for input variables, either
    calculated from supplied data or from the ``minmax`` variable
    in the config. file.  It is possible to calculate for multiple
    data sets using the same min - max range, e.g.::

        R --no-save -f calc_ED.R --args myProject_2000.R
        R --no-save -f calc_ED.R --args myProject_2010.R

    with the line::

        source(myProject_2000.minmax.R)

    in ``myProject_2010.R``.

Road correction
---------------

Roads should be classified as "developed" land cover.  100% agricultural
land cover should exclude any developed land cover, including roads.
For very small watersheds with inaccurate land cover and a road, you may
have a very high ``ag_mxr`` and ``dev_mxr``, which distorts the metric.
The correction in ``calc_ED.R`` is to limit the maximum percent agricultural
land cover based on the length of roads in the watershed and the watershed's
area.  See ``example_config.R`` for steps to enable this correction, and
``calc_ED.R`` for implementation.