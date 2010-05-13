class User
	include DataMapper::Resource
	storage_names[:animebytes] = "users_main"

	property :id, Serial, :field => "ID"
	property :enabled, String, :field => "Enabled"
	property :irc_key, String, :field => "IRCKey"
	property :username, String, :field => "Username"
	property :permission_id, Integer, :field => "PermissionID"
	property :uploaded, Integer, :field => "Uploaded"
	property :downloaded, Integer, :field => "Downloaded"
	property :paranoia, Integer, :field => "Paranoia"

	belongs_to :permission, :class_name => 'Permission', :child_key => [:permission_id], :parent_key => :id
	
	def ratio
		uploaded.to_f/downloaded.to_f
	end

end

require 'riddle'
$sphinx = Riddle::Client.new "localhost", 3312

class Permission
	include DataMapper::Resource
	storage_names[:animebytes] = "permissions"
	property :id, Serial, :field => "ID"

	property :name, String, :field => "Name"
	property :level, Integer, :field => "Level"

end

class Channel
	include DataMapper::Resource
	storage_names[:animebytes] = "irc_channels"

	property :channel, String
	property :level, Integer
end

class Series
	include DataMapper::Resource
	storage_names[:animebytes] = "artists"

	property :id, Serial, :field => "ID"
	property :name, String, :field => "Name"

end

class AnimeGroup
	include DataMapper::Resource
	storage_names[:animebytes] = "torrents_group"

	property :id, Serial, :field => "ID"
	property :series_id, Integer, :field => "SeriesID"
	property :year, Integer, :field => "Year"
	property :name, String, :field => "Name"

	belongs_to :series, :class_name => "Series", :child_key => [:series_id], :parent_key => :id
	has n, :anime_group_tag, :class_name => "AnimeGroupTag", :child_key => [:group_id], :parent_key => :id
	has n, :animetags, :class_name => "AnimeTag", :through => :anime_group_tag


	def self.search_first(q)
		$sphinx.match_mode = :extended
		$sphinx.sort_mode = :relevance
		$sphinx.limit = 1
		branch = "_yuki"
		#branch = ""

		m = $sphinx.query(q, "anime#{branch} delta_anime#{branch}")[:matches].first
		if m.nil?
			return
		else
			return AnimeGroup.get(m[:doc])
		end
	end
end

class AnimeGroupTag
	include DataMapper::Resource
	storage_names[:animebytes] = "torrents_tags"

	property :tag_id, Integer, :field => "TagID"
	property :group_id, Integer, :field => "GroupID"
	
	belongs_to :animegroup, :class_name => "AnimeGroup", :child_key => [:group_id], :parent_key => :id
	belongs_to :animetag, :class_name => "AnimeTag", :child_key => [:tag_id], :parent_key => :id
end

class AnimeTag
	include DataMapper::Resource
	storage_names[:animebytes] = "tags"
	
	property :id, Serial, :field => "ID"
	property :name, String, :field => "Name"
	

end
