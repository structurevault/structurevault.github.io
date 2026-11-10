SPARK CENTRE ON A USB STICK
===========================

Setting up the stick (once)
1. Copy everything in this "usb" folder to the top level of the USB stick:
     Start SPARK.bat
     Start SPARK (Mac).command
     spark-update.ps1
     README.txt
2. Plug the stick into a computer with internet and run Start SPARK.
   The first run downloads the whole site (about 140 MB) into a "site" folder on the stick.

Every time after that
- Windows: double-click "Start SPARK.bat"
- Mac:     double-click "Start SPARK (Mac).command"
           (the first time, right-click it > Open, then click Open, because macOS
           blocks scripts it hasn't seen before)

It checks GitHub for changes, downloads only what changed, then opens SPARK Centre
in the browser. With no internet it just opens the copy already on the stick.
The home page shows "USB copy · updated ..." so you can see how fresh it is.

Good to know
- Pages with live data (Bitcoin, earthquakes, Minecraft Live, etc.) still need internet.
  Everything else works offline.
- You can also open site\index.html directly. It just won't check for updates.
- Don't put your own files inside the "site" folder; the updater manages it.
- GitHub allows about 60 update checks per hour per internet connection. If a whole
  class starts at once, some sticks may skip the check and open their saved copy.
- Chromebooks and iPads can't run the launcher. Use https://structurevault.github.io there.
