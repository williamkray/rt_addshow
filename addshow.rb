#!/usr/bin/ruby

require 'yaml'
require 'xmlrpc/client'
require 'fileutils'
require 'pp'

@show_name = ARGV[0]
@show_url = ARGV[1]
@addshow_config = YAML.load_file("#{ENV['HOME']}/.addshow.yml")
@xmlrpc_port = nil
@rt_config_lines = nil
@watch = nil
@dest = nil
@title = nil

# we'll use this to clean up show names that have problematic characters in the title
def sanitize(messy_name)
	return messy_name.gsub(/[ \?\*\:\-\!]/, '_')
end

# this actually creates the watch and destination directories, and if necessary applies the appropriate permissions to them
def make_folders
	permission_error = "####################\n" +
			"WARNING:\n" +
			"####################\n\n" +
			"Looks like you're getting permission issues. Resorting to a more low-brow method of changing permissions" 

	puts "Making folders"
	FileUtils.mkdir_p(@watch_dir)
	FileUtils.mkdir_p(@dest_dir)

	if !@addshow_config['watch']['mode'].nil?
		puts "Changing watch directory permissions"
		FileUtils.chmod(@addshow_config['watch']['mode'], @watch_dir, :verbose => true)
	end

	if !@addshow_config['watch']['owner'].nil? || !@addshow_config['watch']['group'].nil?
		puts "Changing watch directory ownership"
		begin
			FileUtils.chown(@addshow_config['watch']['owner'], @addshow_config['watch']['group'], @watch_dir, :verbose => true)
		rescue
			puts permission_error
			if File.exists?('/usr/bin/sudo')
				`sudo chmod #{@addshow_config['watch']['owner']}:#{@addshow_config['watch']['group']} #{@watch_dir}`
			else
				`su - root -c chmod #{@addshow_config['watch']['owner']}:#{@addshow_config['watch']['group']} #{@watch_dir}`
			end
		end
	end

	if !@addshow_config['dest']['mode'].nil?
		puts "Changing destination directory permissions"
		FileUtils.chmod(@addshow_config['dest']['mode'], @dest_dir, :verbose => true)
	end

	if !@addshow_config['dest']['owner'].nil? || !@addshow_config['dest']['group'].nil?
		begin
			puts "Changing destination directory ownership"
			FileUtils.chown(@addshow_config['dest']['owner'], @addshow_config['dest']['group'], @dest_dir, :verbose => true)
		rescue
			puts permission_error
			if File.exists?('/usr/bin/sudo')
				`sudo chmod #{@addshow_config['watch']['owner']}:#{@addshow_config['watch']['group']} #{@watch_dir}`
			else
				`su - root -c chmod #{@addshow_config['watch']['owner']}:#{@addshow_config['watch']['group']} #{@watch_dir}`
			end
		end
	end

end

# this writes out a string of text with some values in it to add to your rtorrent config file
def get_rt_line
	@rt_config_lines = "\n\n## #{@title}\nschedule = watch_directory_#{@digit},5,5,\"load_start=#{@watch}/*.torrent,d.set_custom1=#{@dest}/d.delete_tied=\""
end

# this appends the necessary lines to our rss app and rtorrent config files
def mod_configs

	# RSS app: skips if no url is supplied, then modifies config based on supported app.
	# if 'none' is selected, skips process. If unrecognized app, exits without making changes.
	if @show_url == nil or @show_url == ""
		puts "No url specified, skipping"
	else
		if @addshow_config['rss']['app'] == 'none'
			puts "No rss app selected, skipping"
		elsif @addshow_config['rss']['app'] == 'rssdler'
			puts "Modifying rssdler config file"
			rssdler_config_lines = "\n\n" +
				"[ #{@clean_name} ]\n"+
				"link=#{@show_url}\n"+
				"directory=#{@watch_dir}"
			File.open(@addshow_config['rss']['config'], 'a') do |f|
				f.write(rssdler_config_lines)
			end
		else
			puts "Sorry, RSS app is unrecognized. Exiting."
			exit
		end
	end

	# rtorrent: checks last line of rtorrent config for previous watch directory number.
	# If not parseable, prints message of dummy line to add to end of file manually,
	# with option to automatically add it now.
	# Otherwise, increments number by one and adds config line for new watch directory.

	@digit = 0
	@watch = "dummy"
	@dest = "dummy"
	@title = "Dummy Line"
	
	while @digit == 0 or @digit == nil
		get_rt_line
		rt_last_line = File.readlines(@addshow_config['rtorrent']['config_shows'])[-1]
		@digit = rt_last_line.split(',').first.to_s.split(//).last(4).join.to_i unless rt_last_line !~ /watch_directory_/
		if @digit == nil or @digit == 0
			@digit = 1000
			get_rt_line
			puts "Hmm, I'm having some trouble configuring your rtorrent file.\n"+
				"Would you like to automatically add the following dummy line to the end of it?"+
				"#{@rt_config_lines}\n\n"+
				"(Y[es] to add it, N[o] to exit without making changes)"
			mod_rtorrent = nil
			while mod_rtorrent == nil
				mod_rtorrent = $stdin.gets.chomp!
				if mod_rtorrent =~ /^[Yy][Ee]*[Ss]*/
					File.open(@addshow_config['rtorrent']['config_shows'], 'a') do |f|
						f.write(@rt_config_lines)
					end
					@digit = 0
				elsif mod_rtorrent =~ /^[Nn][Oo]*$/
					puts "Exiting"
					exit
				else
					puts "I didn't catch that. Try again."
					mod_rtorrent = nil
				end
			end
		end
	end

	@digit += 1
	@watch = @watch_dir
	@dest = @dest_dir
	@title = @show_name

	get_rt_line

	puts "Adding the following lines to the rtorrent config:"+
		"#{@rt_config_lines}"+"\n"
		
	File.open(@addshow_config['rtorrent']['config_shows'], 'a') do |f|
		f.write(@rt_config_lines)
	end

end

def reload_rtorrent
	if @xmlrpc_port == nil
		puts "No xmlrpc port defined, skipping rtorrent reload. You can reload your config file manually, or restart rtorrent to see configuration changes."
	else
		puts "Reloading rtorrent config file..."
		conn = XMLRPC::Client.new('localhost', '/RPC2', 80)
		begin
			conn.call('import', '', "#{@addshow_config['rtorrent']['config_shows']}")
			puts "Done!"
		rescue XMLRPC::FaultException => e
			puts "Whoa, looks like your xmlrpc configuration on rtorrent is a little funny. You'll have to reload or restart rtorrent manually. The full error is below:"
			puts e.faultString
			exit
		end
	end
end

File.read(@addshow_config['rtorrent']['config_main']).each_line do |line|
	if line =~ /^\s*scgi_port/
		@xmlrpc_port = line.split(':').last
	end
end

if @xmlrpc_port.nil?
	puts "####################\n" +
	"WARNING: rtorrent not configured for xmlrpc interface. rtorrent will be need to be MANUALLY RESTARTED/RELOADED.\n" +
	"####################"
end

if @show_name.nil?
	print "Name of show: "
	@show_name = $stdin.gets.chomp
end

if @show_url.nil?
	print "URL for RSS feed (leave blank for none): "
	@show_url = $stdin.gets.chomp
end

@clean_name = sanitize(@show_name)
@watch_dir = "#{@addshow_config['watch']['path']}/#{@clean_name}"
@dest_dir = "#{@addshow_config['dest']['path']}/#{@clean_name}"

puts "the following configurations are set:\n
	RSS config file: #{@addshow_config['rss']['config']}
	rtorrent config file: #{@addshow_config['rtorrent']['config_shows']}
	watch directory: #{@watch_dir}
	destination directory: #{@dest_dir}
	Show name: #{@show_name}
	RSS URL: #{@show_url}

Does this look correct?"

confirm = nil
while confirm.nil?
	confirm = $stdin.gets.chomp!
	if confirm =~ /^[Yy][Ee]*[Ss]*/
		if !File.exists?(@addshow_config['rtorrent']['config_shows'])
			File.open(@addshow_config['rtorrent']['config_shows'], "w")
		end
		make_folders
		mod_configs
		reload_rtorrent
	elsif confirm =~ /^[Nn][Oo]*$/
		puts "K, never mind. Exiting."
	else
		puts "I didn't catch that. Try again."
		confirm = nil
	end
end


