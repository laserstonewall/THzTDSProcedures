# THzTDSProcedures

These procedures are written for use with [Igor Pro](https://www.wavemetrics.com/products/igorpro/igorpro.htm), an application for processing of experimental data written and sold by [WaveMetrics](https://www.wavemetrics.com/index.html).

This procedure will do basic processing on time domain THz files given a time column, and X and Y channels of a lockin amplifier (The Y channel is not strictly necessary). While initially written for time domain THz traces, the routines can be used to process FFTs of any x vs. y style trace.

### Running the procedures

To be able to access the procedures, the main .ipf file must be placed either in the same folder as the current Igor experiment, which will make it only accessible to that particular experiment, or it must be placed in the User Files directory, making it accessible across all Igor experiments. 

The procedures are usually accessed via a control panel GUI that makes loading and processing files easy. In your experiment, the control panel can be accessed by either running "Display THz control panel" in the macros menu, or else by running ChrisTHz() from the Igor command line.

If desired, the source code has individual supporting functions to perform basic operations such as loading in a file from a given directory, performing FFTs with specified parameters, etc.

### Credits

The procedures were developed in the [group](https://sites.google.com/site/nparmitagegroup/) of Professor [Peter Armitage](http://physics-astronomy.jhu.edu/directory/n-peter-armitage/) in the [Johns Hopkins University Physics Department](http://physics-astronomy.jhu.edu/).

### Contact

If you have found this code useful, have suggetions, or have questions/need help working with the procedures, please feel free to contact me at morris.chris.m@gmail.com.
