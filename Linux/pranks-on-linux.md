### Prerequisites 
Make sure the following are installed on the remote Linux Machine that you want to play a prank on : 
- openssh / sshd is up and running on the remote machine so you can login
- mpv
- xdotool
- xrandr / xterm
- pactl

### Getting ready :
```bash
ssh user@remote-machine
export DISPLAY=:0  # it's usually always 0 unless it has multiple displays
```

### Opening tabs with 'scary' pictures on brave : 
```bash
xdotool search --onlyvisible --class "Brave-browser" windowfocus key Ctrl+t type 'https://pics.craiyon.com/2023-06-29/841dd65c8aa64021903664c9d2fc9f2c.webp' && xdotool search --onlyvisible --class "Brave-browser" windowfocus key Ctrl+Enter
```
Or for Firefox : 
```bash
xdotool search --onlyvisible --class "Firefox" windowfocus key Ctrl+t type 'https://pics.craiyon.com/2023-06-29/841dd65c8aa64021903664c9d2fc9f2c.webp' && xdotool search --onlyvisible --class "Firefox" windowfocus key Ctrl+Enter
```

### Opening text on geany (or pick up another text editor installed) and typing 
```bash
geany &
sleep 5
WID=$(/usr/bin/xdotool search --onlyvisible --class "geany")
if [ -n "$WID" ]; then
  xdotool windowactivate --sync $WID
  # Optional: Wait a moment after activation to ensure the window is ready.
  sleep 1
  xdotool type --delay 10 "Hello World"
fi
```

### Open a bunch of empty terminals
```bash
for i in {1..10}; do xterm & done
```

### Play with the display 
```bash
xrandr # to detect the current display 
xrandr --output eDP-1 --rotate inverted # invert display
xrandr --output eDP-1 --rotate normal # restore to normal
```

### Play scary sounds or video files with mpv while maxing out the volume
Make sure to download the audio/video files on the remote machine before playing the prank
```bash
# Store the current volume level
CURRENT_VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+%' | head -1)
# Set the volume to 50%, you can adjust this value as needed
pactl set-sink-volume @DEFAULT_SINK@ 100%
# Play the scary music track in the background
mpv /home/user/hah1.mp3 &
# After the prank, you can stop the music by killing the mpv process
killall mpv
# And restore the original volume level
pactl set-sink-volume @DEFAULT_SINK@ $CURRENT_VOLUME
```
