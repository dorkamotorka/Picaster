# File Sharing

I assume there are more than just mentioned tools, but that kind-a cleared my mind what to use when it comed down to netbooting:

## Network File System (NFS)

NFS is a protocol that enables you to share the whole file system with other machine on a local network. Pretty practical when you want to netboot it. It is build upon Remote Procedure Call (RPC). 
One things that is really important is that running a NFS Server is native to Unix operating systems, so forget about it when you think about Windows. I mean some people are using it on Windows, but it is far more common to use Samba or NetWare Core Protocol(NCP), because NFS is complex to setup (on Windows).

## Sambda

Sambda is an re-implementation of the Share Message Block(SMB) networking protocol. SMB is the native file sharing protocol implemented on Windows.
NFS has a better performance then Samba when it comes to reading/writing medium size files(1MiB, 10KiB).


## Trivial File Transfer Protocol (TFTP) 

TFTP is a simple lockstep(fault-tolerant) protocol which allows a machine to get a file from or put a file onto a remote host. It's primary usage was to sent boot files to remote host and consequently boot them through the network.

### TODO: FTP, SCP, SFTP
