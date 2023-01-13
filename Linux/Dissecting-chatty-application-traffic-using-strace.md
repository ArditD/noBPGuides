# Dissecting chatty application traffic using strace 

## Environment
- Linux ws 6.1.4-arch1-1
- strace 6.1-2
- systemd 252.4-2

*******************
## For the Impatient
******************* 

## Step 1 : Firing strace & the chatty app (example) : 
```
$   strace -r -f -e trace=connect,openat firefox > log 2>&1
```

## Step 2 : Processing the data & making it readable
```
cat log | grep -E 'sin_addr=inet_addr|sin6_addr|/run/systemd/machines/' | grep -E -v '127.0.0.1|getsockname' | cut -d '"' -f 2 | sort -u | cut -d '/' -f5
```

That's it, done. Here's an example output : 

```
content-signature-2.cdn.mozilla.net
contile.services.mozilla.com
detectportal.firefox.com
example.org
firefox.settings.services.mozilla.com
incoming.telemetry.mozilla.org
ipv4only.arpa
ocsp.digicert.com
push.services.mozilla.com
r3.o.lencr.org
192.0.0.170
192.0.0.171
2.19.126.208
2.19.126.223
2600:1901:0:38d7::
2600:1901:0:92a9::
2606:2800:220:1:248:1893:25c8:1946
2a02:26f0:10e::5435:a1c0
2a02:26f0:10e::5435:a1c3
34.107.221.82
34.117.237.239
34.160.144.191
35.160.45.85
35.165.191.28
52.38.198.114
52.41.34.173
52.43.158.219
52.43.253.52
52.89.255.30
54.201.77.8
93.184.216.34
93.184.220.29
```
*******************
## For the curious & diligent
*******************

## Hmmm, explain!
First of all, with strace I traced for connect and openat.
Connect will take care of the IPv4 / IPv6 traffic, while openat is not specifically related to DNS, but on systemd systems it will make that kind of request to /run/systemd/machines/domain-name.com  , I know it's quite interesting, but it's a sure fire method, I verified it also with a dnsproxy in the middle and everything which was caught by strace was also logged in the proxy.

cat / cut / grep , basically filters and cleans out all the interesting data which is the domains, IPv4 addresses, and IPv6

## What to do with the data?
It's up to you if you : 
- decide to take a deeper dive and get into decrypting traffic AND/OR
- add read/write to see what the program is accessing with strace  AND/OR 
- Lookup reverse IP, ASN's, blacklist checks, etc  AND/OR
- Create a local firewall that blocks that kind of traffic if you don't like it that chatty (not advisable, btw you'll look alone in the crowd :P )

## Interested in expanding on Network Syscalls?

| Syscall     | Number|Description | 
| ----------- |-------|----------- |
|[SOCKET](http://man7.org/linux/man-pages/man2/socket.2.html) | 41| Create an endpoint for communication |
|[SOCKETPAIR](http://man7.org/linux/man-pages/man2/socketpair.2.html) |53 |Create a pair of connected sockets |
|[SETSOCKOPT](http://man7.org/linux/man-pages/man2/setsockopt.2.html)|54 |Set options on sockets |
|[GETSOCKOPT](http://man7.org/linux/man-pages/man2/getsockopt.2.html) |55 |Get options on sockets |
|[GETSOCKNAME](http://man7.org/linux/man-pages/man2/getsockname.2.html) |51 |Get socket name |
|[GETPEERNAME](http://man7.org/linux/man-pages/man2/getpeername.2.html) | 42|Get name of connected peer socket |
|[BIND](http://man7.org/linux/man-pages/man2/bind.2.html) | 49| Bind a name to a socket|
|[LISTEN](http://man7.org/linux/man-pages/man2/listen.2.html) |50 |Listen for connections on a socket |
|[ACCEPT](http://man7.org/linux/man-pages/man2/accept.2.html)|43 |Accept a connection on a socket |
|[ACCEPT4](http://man7.org/linux/man-pages/man2/accept4.2.html)| 288| Accept a connection on a socket|
|[CONNECT](http://man7.org/linux/man-pages/man2/connect.2.html)| 42|Initiate a connection on a socket |
|[SHUTDOWN](http://man7.org/linux/man-pages/man2/shutdown.2.html)  |48 |Shut down part of a full-duplex connection |

##### Other Network Syscalls

[RECVFROM](http://man7.org/linux/man-pages/man2/recvfrom.2.html) [RECVMSG](http://man7.org/linux/man-pages/man2/recvmsg.2.html) [RECVMMSG](http://man7.org/linux/man-pages/man2/recvmmsg.2.html) [SENDTO](http://man7.org/linux/man-pages/man2/sendto.2.html) [SENDMSG](http://man7.org/linux/man-pages/man2/sendmsg.2.html) [SENDMMSG](http://man7.org/linux/man-pages/man2/sendmmsg.2.html)
[SETHOSTNAME](http://man7.org/linux/man-pages/man2/sethostname.2.html) [SETDOMAINNAME](http://man7.org/linux/man-pages/man2/setdomainname.2.html) [BPF](http://man7.org/linux/man-pages/man2/bpf.2.html)

You can check as well http://linasm.sourceforge.net/docs/syscalls/index.php for details, it's basically the best.