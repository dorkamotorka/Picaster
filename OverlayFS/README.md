# OverlayFS

Overlay filesystems, also known as "union filesystems" or "union mounts" enables user to create layered structure of their file systems, directories.
e.g. With command:

	mount -t overlay overlay -o lowerdir=/lower,upperdir=/upper,workdir=/work /merged

You create lower,upper and overlay(merged) layer, where the side-effect is that:
- lowerdir is read-only
- upperdir is read-write
- overlay(merged) is both lowerdir and upperdir combined together

The two are not neccesary directories but could also be the roots of two file systems 

Potentially you could create multiple lower read-only directories, where you should specify them in the command above as:
	
	mount -t overlay overlay -o lowerdir=/lower1:/lower2:/lower3,upperdir=/upper,workdir=/work /merged # The rightmost directory is the lowest one

Usage points, when a process:
- reads a file in the /merged directory, the overlayfs filesystem driver looks in the upper directory and reads the file from there if it’s present. Otherwise, it looks in the lower directory.
- writes a file in the /merged directory, overlayfs will write it to the /upper and /merged directory
- writes a file in the /upper directory, overlayfs will write it to the /upper and /merged directory
- writes a file in the /lower directory, overlayfs will write it to the /lower and /merged directory
- removes a file from the /merged directory, overlayfs will only delete file in the /merged directory, but in the /upper directory this file became a ... character device? I guess this is how the overlayfs driver represents a file being deleted. This file is also reffered to as a whiteout.
- removes a file from the /lower directory, overlayfs will delete it from the read-only /lower directory
- removes a file from the /upper directory, overlayfs will delete it in the /upper and /merged directory

