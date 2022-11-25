# Guide to quickly decrypt TLSv1.3 using tcpdump / Wireshark | tshark

Works also with TLSv1.2

## Environment
- Linux ws 6.0.9-arch1-1 #1 SMP PREEMPT_DYNAMIC Wed, 16 Nov 2022 17:01:17 +0000 x86_64 GNU/Linux
- Wireshark : Version         : 4.0.1-1
- A server that supports    TLSv1.3 

### Step 1 : Prepare the capture
```
$   sudo tcpdump -s0 -nnvvi eth4 port 443 -w capture.cap
```
> -s0 for full packet capture
> it's advisable to add further filters if your destination is a specific 
> website

### Step 2 : Fire the client that will be generating TLSv1.3 / HTTPs traffic and set the env var
```
$   SSLKEYLOGFILE=/home/qacicd/tlskeylogfile.log firefox 
```
> You will be generating traffic with your TLS client (it can be curl, openssl, firefox, chrome, a robot framework selenium session, whatever client that supports TLS)
> The file will collect Client/Server handshake secrets via env variable used to decrypt that same traffic.

### Step 3 : Decrypt the traffic using tshark (Wireshark CLI)
```
$   tshark -o tls.keylog_file:tlskeylogfile.log -r capture.cap -Y tls | grep -i "http"
```



### For those used to Wireshark UI
1) Open the cap with wireshark 
2) Go to Edit > Preferences > Protocols > TLS > and specify the (Pre)-Master-Secret-log filename i.e (tlskeylogfile.log)
3) Type http on the top bar of wireshark (Apply to display filter)




