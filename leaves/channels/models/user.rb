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
