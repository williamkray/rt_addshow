DESCRIPTION:
============

This script will automatically update your rtorrent and rss application configurations to make adding a torrent rss subscription easy!

What does it do:
	1. creates a unique watch directory for rtorrent to automatically start downloads
	2. creates a unique destination directory for rtorrent to move the download when it is finished, while still seeding the file
	3. adds the rss url to the rss application's config file (if a url is provided)
	4. adds the watch and destination directories to the rtorrent config file
	5. seamlessly reloads the rtorrent config to activate the new watch directory (if rtorrent is configured to listen for xmlrpc calls)

Features:
	+ supports rssdler as the rss application (plans to support flexget in the future)
	+ supports creating directories with specific ownership and permissions
	+ can create rtorrent directories without requiring a URL. makes it easy to add unique watch folders for different things!

SETUP:
======
I strongly recommend setting a secondary rtorrent config file for your shows, and adding the following line to your main rtorrent config file (assuming the secondary config is called ~/.rtorrent.shows): 

	import=~/.rtorrent.shows

This will allow you to easily reload the config without rtorrent complaining about a bunch of stuff that only should happen at boot.
If you have xmlrpc configured for your rtorrent installation (if you're using any sort of client for rtorrent, like ruTorent or something like that, then you do), the addshow script will reload this config for you. great! Note: currently only recognizes calls configured on a port. Socket support planned in the future.

copy addshow.yml to your home directory as a dot file (/home/username/.addshow.yml). This is just the default location it will look for the file, but if you want, you can hard-code a file path to the config by changing the "@addshow_config" line to be a full path, like:
	@addshow_config = "/etc/addshow/addshow.yml"

edit the yml file as indicated in the comments.

USAGE:
======

you can pass arguments for a show, or it will prompt you. To pass it arguments, you could do something like this:

[user@box] $ addshow.rb "An Awesome TV Show" "http://www.tvshow-url.com/rss"

or simply run the script and it will prompt you for a tv show name and RSS url. If you don't have an RSS url, you can leave it empty. To avoid having it ask for a url, choose "none" as your RSS app in the addshow.yml config.

This script currently only supports rssdler (https://code.google.com/p/rssdler/) with plans to support flexget in the future, but i'm not there yet.

If the script has trouble reloading the rtorrent config, or your rtorrent is not configured to use xmlrpc commands, you will need to manually reload or restart rtorrent to see changes. to reload the config from the rtorrent n-curses interface, hit CTRL-X to run a command, and type the same line as the one you added to your config file. easy.

If you have specific needs about the file ownership of the watch and destination directories, you can designate them in the yml config file. If your user account doesn't have the proper permissions, you will be prompted for either the root or sudo password.
