DESCRIPTION:
============

This script will automatically update your rtorrent and rss application configurations to make adding a torrent rss subscription easy!

SETUP:
======
I strongly recommend setting a secondary rtorrent config file for your shows, and adding the following line to your main rtorrent config file (assuming the secondary config is called ~/.rtorrent.shows): 

import=~/.rtorrent.shows

This will allow you to easily reload the config without rtorrent complaining about a bunch of stuff that only should happen at boot.
If you have xmlrpc configured for your rtorrent installation (if you're using any sort of client for rtorrent like ruTorent or something like that, then you do), the addshow script will reload this config for you. great!

copy addshow.yml to your home directory as a dot file (/home/username/.addshow.yml)

edit it as indicated in the comments.

put the addshow.rb script somewhere in your path so you can run it. make it executable if you don't want to call ruby to run it.

USAGE:
======

you can pass it arguments for a show, or it will prompt you. To pass it arguments, you could do something like this:

[user@box] $ addshow.rb "An Awesome TV Show" "http://www.tvshow-url.com/rss"

or simply run the script and it will prompt you for a tv show name and RSS url. If you don't have an RSS url, you can leave it empty.

This script currently only supports rssdler (https://code.google.com/p/rssdler/) with plans to support flexget in the future, but i'm not there yet.

If the script has trouble reloading the rtorrent config, or your rtorrent is not configured to use xmlrpc commands, you will need to manually reload or restart rtorrent to see changes. to reload the config from the rtorrent n-curses interface, hit CTRL-X to run a command, and type the same line as the one you added to your config file. easy.

If you have specific needs about the file ownership of the watch and destination directories, you can designate them in the yml config file. However, this assumes that you run the script with sudo, or as root, with also assumes that the config file exists in root's home directory. Otherwise, it would probably be easiest to run the script as the user with the proper permissions.
