module Autumn

  # A connection to an IRC server. The stem acts as the IRC client on which a
  # Leaf runs. It receives messages from the IRC server and sends messages to
  # the server. Stem is compatible with many IRC daemons; details of the IRC
  # protocol are handled by a Daemon instance. (See **Compatibility with
  # Different Server Types**, below).
  #
  # Generally stems are initialized by the {Foliater}, but should you want to
  # instantiate one yourself, a Stem is instantiated with a server to connect to
  # and a nickname to acquire (see the {#initialize} method docs). Once you
  # initialize a Stem, you should call {#add_listener} one or more times to
  # indicate to the stem what objects are interested in working with it.
  #
  # Listeners and Listener Plug-Ins
  # -------------------------------
  #
  # An object that functions as a listener should conform to an implicit
  # protocol. See the {#add_listener} docs for more information on what methods
  # you can implement to listen for IRC events. Duck typing is used -- you need
  # not implement every method of the protocol, only those you are concerned
  # with.
  #
  # Listeners can also act as plugins: Such listeners add functionality to
  # other listeners (for example, a CTCP listener that adds CTCP support to
  # other listeners, such as a Leaf instance). For more information, see the
  # {#add_listener} docs.
  #
  # Starting the IRC Session
  # ------------------------
  #
  # Once you have finished configuring your stem and you are ready to begin the
  # IRC session, call the {#start} method. This method blocks until the the
  # socket has been closed, so it should be run in a thread. Once the connection
  # has been made, you are free to send and receive IRC commands until you close
  # the connection, which is done with the `quit` method.
  #
  # Receiving and Sending IRC Commands
  # ----------------------------------
  #
  # Receiving events is explained in the {#add_listener} docs. To send an IRC
  # command, simply call a method named after the command name. For instance, if
  # you wish to `PRIVMSG` another nick, call the `privmsg` method. If you wish
  # to `JOIN` a channel, call the `join` method. The parameters should be
  # specified in the same order as the IRC command expects.
  #
  # (That being said, you should _actually_ use the {StemFacade#join_channel}
  # method to join channels, because it is better.)
  #
  # For more information on what IRC commands are "method-ized", see the
  # {IRC_COMMANDS} constant. For more information on the proper way to use these
  # commands (and thus, the methods that call them), consult the {Daemon} class.
  #
  # Compatibility with Different Server Types
  # -----------------------------------------
  #
  # Many different IRC server daemons exist, and each one has a slightly
  # different IRC implementation. To manage this, there is an option called
  # `server_type`, which is set automatically by the stem if it can determine
  # the IRC software that the server is running. Server types are instances of
  # the {Daemon} class, and are associated with a name. A stem's server type
  # affects things like response codes, user modes, and channel modes, as these
  # vary from server to server.
  #
  # If the stem is unsure what IRC daemon your server is running, it will use
  # the {Daemon.default default} Daemon instance. This default server type will
  # be compatible with nearly every server out there. You may not be able to
  # leverage some of the more esoteric IRC features of your particular server,
  # but for the most common uses of IRC (sending and receiving messages, for
  # example), it will suffice.
  #
  # If you'd like to manually specify a server type, you can pass its name for
  # the `server_type` initialization option. Consult the `resources/daemons`
  # directory for valid Daemon names and hints on how to make your own Daemon
  # specification, should you desire.
  #
  # Channel Names
  # -------------
  #
  # The convention for Autumn channel names is: When you specify a channel to
  # an Autumn stem, you can (but don't have to) prefix it with the '#'
  # character, if it's a normal IRC channel. When an Autumn stem gives a channel
  # name to you, it will always start with the '#' character (assuming it's a
  # normal IRC channel, of course). If your channel is prefixed with a different
  # character (say, '&'), you will need to include that prefix every time you
  # pass a channel name to a stem method.
  #
  # So, if you would like your stem to send a message to the "#kittens" channel,
  # you can omit the '#' character; but if it's a server-local channel called
  # "&kittens", you will have to provide the '&' character. Likewise, if you are
  # overriding a hook method, you can be guaranteed that the channel given to
  # you will always be called "#kittens", and not "kittens".
  #
  # Synchronous Methods
  # -------------------
  #
  # Because new messages are received and processed in separate threads, methods
  # can sometimes receive messages out of order (for instance, if a first
  # message takes a long time to process and a second message takes a short time
  # to process). In the event that you require a guarantee that your method will
  # receive messages in order, and that it will only be invoked in a single
  # thread, annotate your method with the `stem_sync` property.
  #
  # For instance, you might want to ensure that you are finished processing 353
  # messages (replies to `NAMES` commands) before you tackle 366 messages (end
  # of `NAMES` list). To ensure these methods are invoked in the correct order:
  #
  # ```` ruby
  # class MyListener
  #   def irc_rpl_namreply_response(stem, sender, recipient, arguments, msg)
  #     [...]
  #   end
  #
  #   def irc_rpl_endofnames_response(stem, sender, recipient, arguments, msg)
  #     [...]
  #   end
  #
  #   ann :irc_rpl_namreply_response, stem_sync: true
  #   ann :irc_rpl_endofnames_response, stem_sync: true
  # end
  # ````
  #
  # All such methods will be run in a single thread, and will receive server
  # messages in order. Because of this, it is important that synchronized
  # methods do not spend a lot of time processing a single message, as it forces
  # all other synchronous methods to wait their turn.
  #
  # This annotation is only relevant to "invoked" methods, those methods in
  # listeners that are invoked by the stem's broadcast method. Methods that are
  # marked with this annotation will also run faster, because they don't have
  # the overhead of setting up a new thread.
  #
  # Many of Stem's own internal methods are synchronized, to ensure internal
  # data such as the channels list and channel members list stays consistent.
  # Because of this, any method marked as synchronized can be guaranteed that
  # the stem's channel data is consistent and "in sync" for the moment of time
  # that the message was received.
  #
  # Throttling
  # ----------
  #
  # If you send a message with the `privmsg` command, it will not be throttled.
  # (Most IRC servers have some form of flood control that throttles rapid
  # `PRIVMSG` commands, however.)
  #
  # If your IRC server does not have flood control, or you want to use
  # client-side flood control, you can enable the `throttling` option. The stem
  # will throttle large numbers of simultaneous messages, sending them with
  # short pauses in between.
  #
  # The `privmsg` command will still _not_ be throttled (since it is a facade
  # for the pure IRC command), but the {StemFacade#message} command will gain
  # the ability to throttle its messages.
  #
  # By default, the stem will begin throttling when there are five or more
  # messages queued to be sent. It will continue throttling until the queue is
  # emptied. When throttling, messages will be sent with a delay of one second
  # between them. These options can be customized (see the initialize method
  # options).

  class Stem
    include StemFacade
    extend Anise::Annotations

    # Describes all possible channel names. Omits the channel prefix, as that
    # can vary from server to server. (See {#channel?})
    CHANNEL_REGEX = "[^\\s\\x7,:]+"
    # The default regular expression for IRC nicknames.
    NICK_REGEX    = "[a-zA-Z][a-zA-Z0-9\\-_\\[\\]\\{\\}\\\\|`\\^]+"

    # @private A parameter in an IRC command.
    class Parameter
      attr_reader :name, :required, :colonize, :list, :truncatable, :splittable

      def initialize(newname, options={})
        @name        = newname
        @required    = options[:required].nil? ? true : options[:required]
        @colonize    = options[:colonize]
        @list        = options[:list]
        @truncatable = options[:truncatable]
        @splittable  = options[:splittable]
      end
    end

    # @private
    def self.param(name, opts={})
      Parameter.new(name, opts)
    end

    # Valid IRC command names, mapped to information about their parameters.
    IRC_COMMANDS = {
        pass:    [param('password')],
        nick:    [param('nickname')],
        user:    [param('user'), param('host'), param('server'), param('name')],
        oper:    [param('user'), param('password')],
        quit:    [param('message', required: false, colonize: true, truncatable: true)],

        join:    [param('channels', list: true), param('keys', list: true)],
        part:    [param('channels', list: true)],
        mode:    [param('channel/nick'), param('mode'), param('limit', required: false), param('user', required: false), param('mask', required: false)],
        topic:   [param('channel'), param('topic', required: false, colonize: true)],
        names:   [param('channels', required: false, list: true)],
        list:    [param('channels', required: false, list: true), param('server', required: false)],
        invite:  [param('nick'), param('channel')],
        kick:    [param('channels', list: true), param('users', list: true), param('comment', required: false, colonize: true, truncatable: true)],

        version: [param('server', required: false)],
        stats:   [param('query', required: false), param('server', required: false)],
        links:   [param('server/mask', required: false), param('server/mask', required: false)],
        time:    [param('server', required: false)],
        connect: [param('target server'), param('port', required: false), param('remote server', required: false)],
        trace:   [param('server', required: false)],
        admin:   [param('server', required: false)],
        info:    [param('server', required: false)],

        privmsg: [param('receivers', list: true), param('message', colonize: true, truncatable: true, splittable: true)],
        notice:  [param('nick'), param('message', colonize: true, truncatable: true, splittable: true)],

        who:     [param('name', required: false), param('is mask', required: false)],
        whois:   [param('server/nicks', list: true), param('nicks', list: true, required: false)],
        whowas:  [param('nick'), param('history count', required: false), param('server', required: false)],

        pong:    [param('code', required: false, colonize: true)],

	chgident: [ param('name', :required => true), param('username', :required => true) ],
	chghost:  [ param('name', :required => true), param('hostname', :required => true) ],
	sajoin:   [ param('name', :required => true), param('rooms', :required => true) ]
    }

    # @return [String] The hostname of the server this stem is connected to.
    attr :server
    # @return [Integer] The remote port that this stem is connecting to.
    attr :port
    # @return [Integer] The local IP to bind to (for virtual hosting).
    attr :local_ip
    # @return [Hash<Symbol, Object>] The global configuration options plus those
    #   for the current season and this stem.
    attr :options
    # @return [Array<String>] The channels that this stem is a member of.
    attr :channels
    # @return [LogFacade] The logger instance handling this stem.
    attr :logger
    # @return [#call] A Proc that will be called if a nickname is in use. It
    #   should take one argument, the nickname that was unavailable, and return
    #   a new nickname to try. The default Proc appends an underscore to the
    #   nickname to produce a new one, or `GHOST`s the nick if possible. This
    #   Proc should return `nil` if you do not want another `NICK` attempt to be
    #   made.
    attr :nick_generator
    # @return [Regexp] The regular expression for valid nicks, as a string. By
    #   default it's equal to {NICK_REGEX}.
    attr :nick_regex
    # @return [Daemon] The Daemon instance that describes the IRC server this
    #   client is connected to.
    attr :server_type
    # @return [Hash<String, Array<String>] A hash of channel members by channel
    #   name.
    attr :channel_members

    # Creates an instance that connects to a given IRC server and requests a
    # given nick.
    #
    # @param [String] server The server hostname.
    # @param [String] newnick The nick to use.
    # @param [Hash] opts Additional options.
    # @option opts [Integer] :port (6667) The port that the IRC client should
    #   connect on.
    # @option opts [Integer] :local_ip Set this if you want to bind to an IP
    #   other than your default (for virtual hosting).
    # @option opts [LogFacade] :logger Specifies a logger instance to use. If
    #   none is specified, a new LogFacade instance is created for the current
    #   season.
    # @option opts [true, false] :ssl If true, indicates that the connection
    #   will be made over SSL.
    # @option opts [String] :user The username to transmit to the IRC server.
    #   (By default it's the user's nick.)
    # @option opts [String] :name The real name to transmit to the IRC server.
    #   (By default it's the user's nick).
    # @option opts [String] :server_password The server password (not the nick
    #   password), if necessary.
    # @option opts [String] :password The password to send to NickServ, if your
    #   leaf's nick is registered.
    # @option opts [String] :channel The name of a channel to join.
    # @option opts [Array<String>] :channels An array of channel names to join.
    # @option opts [String] :sever_type The name of the server type (see
    #   {Daemon}). If left blank, the default Daemon instance is used.
    # @option opts [true, false] :rejoin If `true`, the stem will rejoin a
    #   channel it is kicked from.
    # @option opts [true, false] :case_sensitive_channel_names If `true`,
    #   indicates to the IRC client that this IRC server uses case-sensitive
    #   channel names.
    # @option opts [true, false] :dont_ghost If `true`, does not issue a
    #   `/ghost` command if the stem's nick is taken. (This is only relevant if
    #   the nick is registered and `:password` is specified.) **You should use
    #   this on IRC servers that don't use "NickServ" -- otherwise someone may
    #  change their nick to NickServ and discover your password!**
    # @option opts [true, false] :ghost_without_password Set this to `true` if
    #   your IRC server uses hostname authentication instead of password
    #   authentication for `GHOST` commands.
    # @option opts [true, false] :throttle If enabled, the stem will throttle
    #   large amounts of simultaneous messages.
    # @option opts [Integer] :throttle_rate (1) Sets the number of seconds that
    #   pass between consecutive `PRIVMSG`s when the leaf's output is throttled.
    # @option opts [Integer] :throttle_threshold (5) Sets the number of
    #   simultaneous messages that must be queued before the leaf begins
    #   throttling output.
    # @option opts [Integer] :max_message_length (500) Maximum number of
    #   characters in any message transmitted to the server.
    # @option opts [:send, :split, :cut] :when_long (:send) What to do when the
    #   length of a message exceeds `:max_message_length`. When `:send`, does
    #   not change the message. When `:cut`, truncates the message. When
    #   `:split`, splits the message into multiple messages (if applicable,
    #   truncates it otherwise).
    # @option opts [true, false] :detailed_errors Turn this on to have the bot
    #   announce the actual exceptions that are raised in-channel. (By default
    #   it only informs you that an error occurred with no other information.)
    #   **Leave off for live environments, as DataMapper exceptions can include
    #   passwords.**
    #
    # Any channel name can be a one-item hash, in which case it is taken to be
    # a channel name-channel password association.

    def initialize(server, newnick, opts)
      raise ArgumentError, "Please specify at least one channel" unless opts[:channel] || opts[:channels]

      @nick      = newnick
      @server    = server
      @port      = opts[:port]
      @port      ||= 6667
      @local_ip  = opts[:local_ip]
      @options   = opts
      @listeners = Set.new
      @listeners << self
      @logger             = @options[:logger]
      @detailed_errors    = @options[:detailed_errors]
      @nick_generator     = Proc.new do |oldnick|
        if options[:ghost_without_password]
          message "GHOST #{oldnick}", 'NickServ'
          nil
        elsif options[:dont_ghost] || options[:password].nil?
          "#{oldnick}_"
        else
          message "GHOST #{oldnick} #{options[:password]}", 'NickServ'
          nil
        end
      end
      @server_type        = Daemon[opts[:server_type]]
      @server_type        ||= Daemon.default
      @throttle_rate      = opts[:throttle_rate]
      @throttle_rate      ||= 1
      @throttle_threshold = opts[:throttle_threshold]
      @throttle_threshold ||= 5

      @when_long          = (opts[:when_long] || :send).to_sym
      @max_message_length = opts[:max_message_length].to_i
      @max_message_length = 500 if @max_message_length < 1

      @nick_regex = (opts[:nick_regex] ? opts[:nick_regex].to_re : NICK_REGEX)

      @channels = Set.new
      @channels.merge opts[:channels] if opts[:channels]
      @channels << opts[:channel] if opts[:channel]
      @channels.map! do |chan|
        if chan.kind_of? Hash
          { normalized_channel_name(chan.keys.only) => chan.values.only }
        else
          normalized_channel_name chan
        end
      end
      # Make a hash of channels to their passwords
      @channel_passwords = @channels.select { |ch| ch.kind_of? Hash }.mash { |pair| pair }
                                           # Strip the passwords from @channels, making it an array of channel names only
      @channels.map! { |chan| chan.kind_of?(Hash) ? chan.keys.only : chan }
      @channel_members          = Hash.new
      @updating_channel_members = Hash.new # stores the NAMES list as its being built

      if (@throttle = opts[:throttle])
        @messages_queue  = Queue.new
        @messages_thread = Thread.new do
          throttled = false
          loop do
            args = @messages_queue.pop
            throttled = true if !throttled && @messages_queue.length >= @throttle_threshold
            throttled = false if throttled && @messages_queue.empty?
            sleep @throttle_rate if throttled
            privmsg *args
          end
        end
      end

      @chan_mutex   = Mutex.new
      @join_mutex   = Mutex.new
      @socket_mutex = Mutex.new
    end

    # Adds an object that will receive notifications of incoming IRC messages.
    # For each IRC event that the listener is interested in, the listener should
    # implement a method in the form `irc_[event]_event`, where `event` is the
    # name of the event, as taken from the {IRC_COMMANDS} hash. For example, to
    # register interest in `PRIVMSG` events, implement the method:
    #
    # ```` ruby
    # irc_privmsg_event(stem, sender, arguments)
    # ````
    #
    # If you wish to perform an operation each time any IRC event is received,
    # you can implement the method:
    #
    # ```` ruby
    # irc_event(stem, command, sender, arguments)
    # ````
    #
    # The parameters for both methods are as follows:
    #
    # |             |      |                                                                                                                                            |
    # |:------------|:-----|:-------------------------------------------------------------------------------------------------------------------------------------------|
    # | `stem`      | Stem | This Stem instance.                                                                                                                        |
    # | `sender`    | Hash | A sender hash (see the {Leaf} docs).                                                                                                       |
    # | `arguments` | Hash | A hash whose keys depend on the IRC command. Keys can be, for example, `:recipient`, `:channel`, `:mode`, or `:message`. Any can be `nil`. |
    #
    # The `irc_event` method also receives the command name as a symbol.
    #
    # In addition to events, the Stem will also pass IRC server responses along
    # to its listeners. Known responses (those specified by the Daemon) are
    # translated to programmer-friendly symbols using the {Daemon#event} hash.
    # The rest are left in numerical form.
    #
    # If you wish to register interest in a response code, implement a method of
    # the form `irc_[response]_response`, where `response` is the symbol or
    # numerical form of the response. For instance, to register interest in
    # channel-full errors, you'd implement:
    #
    # ```` ruby
    # irc_err_channelisfull_response(stem, sender, recipient, arguments, msg)
    # ````
    #
    # You can also register an interest in all server responses by implementing:
    #
    # ```` ruby
    # irc_response(stem, response, sender, recipient, arguments, msg)
    # ````
    #
    # This method is invoked when the server sends a response message. The
    # parameters for both methods are:
    #
    # |             |                                                                             |                       |
    # |:------------|:----------------------------------------------------------------------------|:----------------------|
    # | `sender`    | String                                                                      | The server's address. |
    # | `recipient` | The nick of the recipient (sometimes "*" if no nick has been assigned yet). |
    # | `arguments` | Array of response arguments, as strings.                                    |
    # | `message`   | An additional message attached to the end of the response.                  |
    #
    # The `irc_server_response` method additionally receives the response code
    # as a symbol or numerical parameter.
    #
    # Please note that there are hundreds of possible responses, and IRC servers
    # differ in what information they send along with each response code. I
    # recommend inspecting the output of the specific IRC server you are working
    # with, so you know what arguments to expect.
    #
    # If your listener is interested in IRC server notices, implement the
    # method:
    #
    # ```` ruby
    # irc_server_notice(stem, server, sender, msg)
    # ````
    #
    # This method will be invoked for notices from the IRC server. Its
    # parameters are:
    #
    # |          |        |                                                                            |
    # |:---------|:-------|:---------------------------------------------------------------------------|
    # | `server` | String | The server's address.                                                      |
    # | `sender` | String | The message originator (e.g., "Auth" for authentication-related messages). |
    # | `msg`    | String | The notice.                                                                |
    #
    # If your listener is interested in IRC server errors, implement the method:
    #
    # ```` ruby
    # irc_server_error(stem, msg)
    # ````
    #
    # This method will be invoked whenever an IRC server reports an error, and
    # is passed the error message. Server errors differ from normal server
    # responses, which themselves can sometimes indicate errors.
    #
    # Some listeners can act as listener plugins; see the {#broadcast} method
    # for more information.
    #
    # If you'd like your listener to perform actions after it's been added to a
    # Stem, implement a method called `added`. This method will be called when
    # the listener is added to a stem, and will be passed the Stem instance it
    # was added to. You can use this method, for instance, to add additional
    # methods to the stem:
    #
    # ```` ruby
    # added(stem)
    # `````
    #
    # Your listener can implement the `stem_ready` method, which will be called
    # once the stem has started up, connected to the server, and joined all its
    # channels. This method is passed the stem instance:
    #
    # ```` ruby
    # stem_ready(stem)
    # ````
    #
    # @param [Object] obj The object to set as a class listener.

    def add_listener(obj)
      @listeners << obj
      obj.class.send :extend, Anise::Annotations
      obj.respond :added, self
    end

    # Sends the method with the name `meth` to all listeners that respond to
    # that method. You can optionally specify one or more arguments. This method
    # is meant for use by **listener plugins**: listeners that add features to
    # other listeners by allowing them to implement optional methods.
    #
    # For example, you might have a listener plugin that adds CTCP support to
    # stems. Such a method would parse incoming messages for CTCP commands, and
    # then use the broadcast method to call methods named after those commands.
    # Other listeners who want to use CTCP support can implement the methods
    # that your listener plugin broadcasts.
    #
    # @note Each method call will be executed in its own thread, and all
    #   exceptions will be caught and reported. This method will only invoke
    #   listener methods that have _not_ been marked as synchronized. (See
    #   **Synchronous Methods** in the class docs.)
    #
    # @param [Symbol] meth The method to broadcast.
    # @param [Array] args Arguments for that method.

    def broadcast(meth, *args)
      asynchronous_listeners_for_method(meth).each do |listener|
        Thread.new do
          begin
            listener.respond meth, *args
          rescue Exception
            options[:logger].error $!

            # Try to report the error if possible
            if @detailed_errors
              message("Listener #{listener.class.to_s} raised an exception responding to #{meth}: " + $!.to_s) rescue nil
            else
              message("Listener #{listener.class.to_s} raised an exception -- check the logs for details.") rescue nil
            end
          end
        end
      end
    end

    # Same as the {#broadcast} method, but only invokes listener methods that
    # _have_ been marked as synchronized.
    #
    # @param (see #broadcast)

    def broadcast_sync(meth, *args)
      synchronous_listeners_for_method(meth).each { |listener| listener.respond meth, *args }
    end

    # Opens a connection to the IRC server and begins listening on it. This
    # method runs until the socket is closed, and should be run in a thread. It
    # will terminate when the connection is closed. No messages should be
    # transmitted, nor will messages be received, until this method is called.
    #
    # In the event that the nick is unavailable, the `nick_generator` Proc will
    # be called.

    def start
      # Synchronous (mutual exclusion) message processing is handled by a
      # producer-consumer approach. The socket pushes messages onto this queue,
      # which are processed by a consumer thread one at a time.
      @messages         = Queue.new
      @message_consumer = Thread.new do
        loop do
          meths = @messages.pop
          begin
            meths.each { |meth, args| broadcast_sync meth, *args }
          rescue
            options[:logger].error $!
          end
        end
      end

      @socket  = connect
      username = @options[:user]
      username ||= @nick
      realname = @options[:name]
      realname ||= @nick

      pass @options[:server_password] if @options[:server_password]
      user username, @nick, @nick, realname
      nick @nick

      while (line = @socket.gets)
        meths = receive line # parse the line and get a list of methods to call
        @messages.push meths # push the methods on the queue; the consumer thread will execute all the synchronous methods
        # then execute all the other methods in their own thread
        meths.each { |meth, args| broadcast meth, *args }
      end
    end

    # @return [true, false] `true` if this stem has started up completely,
    #   connected to the IRC server, and joined all its channels. A period of
    #   10 seconds is allowed to join all channels, after which the stem will
    #   report ready even if some channels could not be joined.

    def ready?
      @ready
    end

    # Normalizes a channel name by placing a "#" character before the name if no
    # channel prefix is otherwise present. Also converts the name to lowercase
    # if the `case_sensitive_channel_names` option is `false`.
    #
    # @param [String] channel A channel name.
    # @param [true, false] add_prefix If `false`, does not add the prefix to the
    #   channel name if it's missing.
    # @return [String] The normalized channel name.

    def normalized_channel_name(channel, add_prefix=true)
      norm_chan = channel.dup
      norm_chan.downcase! unless options[:case_sensitive_channel_names]
      norm_chan = "##{norm_chan}" unless server_type.channel_prefix?(channel[0, 1]) || !add_prefix
      return norm_chan
    end

    # @private
    def method_missing(meth, *args)
      if IRC_COMMANDS.include? meth
        messages = build_irc_message(meth, args)
        messages.each { |message| transmit message }
      else
        super
      end
    end

    # Given a full channel name, returns the channel type as a symbol. Values
    # can be found in the {Daemon} instance.
    #
    # @param [String] channel A channel name with prefix.
    # @return [Symbol] The channel type from its prefix, or `:unknown` if the
    #   prefix is unrecognized.

    def channel_type(channel)
      type = server_type.channel_prefix[channel[0, 1]]
      type ? type : :unknown
    end

    # Returns `true` if the string appears to be a channel name.
    #
    # @param [String] str A string.
    # @return [true, false] Whether the string appears to be a channel name (as
    #   opposed to a nickname, for example).

    def channel?(str)
      prefixes = Regexp.escape(server_type.channel_prefix.keys.join)
      str.match("[#{prefixes}]#{CHANNEL_REGEX}") != nil
    end

    # Returns `true` if the string appears to be a nickname.
    #
    # @param [String] str A string.
    # @return [true, false] Whether the string appears to be a nickname (as
    #   opposed to a channel name, for example).

    def nick?(str)
      str.match(nick_regex) != nil
    end

    # @return [String] The nick this stem is using.
    def nickname() @nick end

    # @private
    def inspect
      "#<#{self.class.to_s} #{server}:#{port}>"
    end

    # @private
    def irc_ping_event(_, _, arguments)
      arguments[:message].nil? ? pong : pong(arguments[:message])
    end
    ann :irc_ping_event, stem_sync: true # To avoid overhead of a whole new thread just for a pong

    # @private
    def irc_rpl_yourhost_response(_, _, _, _, msg)
      return if options[:server_type]
      type = nil
      Daemon.each_name do |name|
        next unless msg.include? name
        if type
          logger.info "Ambiguous server type; could be #{type} or #{name}"
          return
        else
          type = name
        end
      end
      return unless type
      @server_type = Daemon[type]
      logger.info "Auto-detected #{type} server daemon type"
    end
    ann :irc_rpl_yourhost_response, stem_sync: true # So methods that synchronize can be guaranteed the host is known ASAP

    # @private
    def irc_err_nicknameinuse_response(_, _, _, arguments, _)
      return unless nick_generator
      newnick = nick_generator.call(arguments[0])
      nick newnick if newnick
    end

    # @private
    def irc_rpl_endofmotd_response(_, _, _, _, _)
      post_startup
    end

    # @private
    def irc_err_nomotd_response(_, _, _, _, _)
      post_startup
    end

    # @private
    def irc_rpl_namreply_response(_, _, _, arguments, msg)
      update_names_list normalized_channel_name(arguments[1]), msg.words unless arguments[1] == "*" # "*" refers to users not on a channel
    end
    ann :irc_rpl_namreply_response, stem_sync: true # So endofnames isn't processed before namreply

    # @private
    def irc_rpl_endofnames_response(_, _, _, arguments, _)
      finish_names_list_update normalized_channel_name(arguments[0])
    end
    ann :irc_rpl_endofnames_response, stem_sync: true # so endofnames isn't processed before namreply

    # @private
    def irc_kick_event(_, _, arguments)
      if arguments[:recipient] == @nick
        old_pass = @channel_passwords[arguments[:channel]]
        @chan_mutex.synchronize do
          drop_channel arguments[:channel]
          #TODO what should we do if we are in the middle of receiving NAMES replies?
        end
        join_channel arguments[:channel], old_pass if options[:rejoin]
      else
        @chan_mutex.synchronize do
          @channel_members[arguments[:channel]].delete arguments[:recipient]
          #TODO what should we do if we are in the middle of receiving NAMES replies?
        end
      end
    end
    ann :irc_kick_event, stem_sync: true # So methods that synchronize can be guaranteed the channel variables are up to date

    # @private
    def irc_mode_event(_, _, arguments)
      names arguments[:channel] if arguments[:parameter] && server_type.privilege_mode?(arguments[:mode])
    end
    ann :irc_mode_event, stem_sync: true # To avoid overhead of a whole new thread for a names reply

    # @private
    def irc_join_event(_, sender, arguments)
      if sender[:nick] == @nick
        should_broadcast = false
        @chan_mutex.synchronize do
          @channels << arguments[:channel]
          @channel_members[arguments[:channel]]                ||= Hash.new
          @channel_members[arguments[:channel]][sender[:nick]] = :unvoiced
          #TODO what should we do if we are in the middle of receiving NAMES replies?
          #TODO can we assume that all new channel members are unvoiced?
        end
        @join_mutex.synchronize do
          if @channels_to_join
            @channels_to_join.delete arguments[:channel]
            if @channels_to_join.empty?
              should_broadcast = true unless @ready
              @ready            = true
              @channels_to_join = nil
            end
          end
        end
        # The ready_thread is also looking to set ready to true and broadcast,
        # so to prevent us both from doing it, we enter a critical section and
        # record whether the broadcast has been made already. We set @ready to
        # true and record if it was already set to true. If it wasn't already
        # set to true, we know the broadcast hasn't gone out, so we send it out.
        broadcast :stem_ready, self if should_broadcast
      else
        @chan_mutex.synchronize do
          @channel_members[arguments[:channel]][sender[:nick]] = :unvoiced
          #TODO what should we do if we are in the middle of receiving NAMES replies?
          #TODO can we assume that all new channel members are unvoiced?
        end
      end
    end
    ann :irc_join_event, stem_sync: true # So methods that synchronize can be guaranteed the channel variables are up to date

    # @private
    def irc_part_event(_, sender, arguments)
      @chan_mutex.synchronize do
        if sender[:nick] == @nick
          drop_channel arguments[:channel]
        else
          @channel_members[arguments[:channel]].delete sender[:nick]
        end
        #TODO what should we do if we are in the middle of receiving NAMES replies?
      end
    end
    ann :irc_part_event, stem_sync: true # So methods that synchronize can be guaranteed the channel variables are up to date

    # @private
    def irc_nick_event(_, sender, arguments)
      @nick = arguments[:nick] if sender[:nick] == @nick
      @chan_mutex.synchronize do
        @channel_members.each { |chan, members| members[arguments[:nick]] = members.delete(sender[:nick]) }
        #TODO what should we do if we are in the middle of receiving NAMES replies?
      end
    end
    ann :irc_nick_event, stem_sync: true # So methods that synchronize can be guaranteed the channel variables are up to date

    # @private
    def irc_quit_event(_, sender, _)
      @chan_mutex.synchronize do
        @channel_members.each { |chan, members| members.delete sender[:nick] }
        #TODO what should we do if we are in the middle of receiving NAMES replies?
      end
    end
    ann :irc_quit_event, stem_sync: true # So methods that synchronize can be guaranteed the channel variables are up to date

    private

    def connect
      logger.debug "Connecting to #{@server}:#{@port}..."
      socket = TCPSocket.new @server, @port, @local_ip
      return socket unless options[:ssl]
      ssl_context = OpenSSL::SSL::SSLContext.new
      unless ssl_context.verify_mode
        logger.warn "SSL - Peer certificate won't be verified this session."
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      ssl_socket            = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
      ssl_socket.sync_close = true
      ssl_socket.connect
      return ssl_socket
    end

    def transmit(comm)
      @socket_mutex.synchronize do
        raise "IRC connection not opened yet" unless @socket
        logger.debug '>> ' + comm
        @socket.puts comm
      end
    end

    # Parses a message and returns a hash of methods to their arguments
    def receive(comm)
      meths = Hash.new
      logger.debug '<< ' + comm

      arg_str = nil
      msg     = nil
      sender  = nil
      if comm =~ /^NOTICE\s+(.+?)\s+:(.+?)[\r\n]*$/
        sender, msg               = $1, $2
        meths[:irc_server_notice] = [self, nil, sender, msg]
        return meths
      elsif comm =~ /^ERROR :(.+?)[\r\n]*$/
        msg                      = $1
        meths[:irc_server_error] = [self, msg]
        return meths
      elsif comm =~ /^:(#{nick_regex})!(\S+?)@(\S+?)\s+([A-Z]+)\s+(.*?)[\r\n]*$/
        sender           = { nick: $1, user: $2, host: $3 }
        command, arg_str = $4, $5
      elsif comm =~ /^:(#{nick_regex})\s+([A-Z]+)\s+(.*?)[\r\n]*$/
        sender           = { nick: $1 }
        command, arg_str = $2, $3
      elsif comm =~ /^:([^\s:]+?)\s+([A-Z]+)\s+(.*?)[\r\n]*$/
        _, command, arg_str = $1, $2, $3
        _, msg              = split_out_message(arg_str)
      elsif comm =~ /^(\w+)\s+:(.+?)[\r\n]*$/
        command, msg = $1, $2
      elsif comm =~ /^:([^\s:]+?)\s+(\d+)\s+(.*?)[\r\n]*$/
        server, code, arg_str = $1, $2, $3
        arg_array, msg        = split_out_message(arg_str)

        numeric_method  = "irc_#{code}_response".to_sym
        readable_method = nil
        readable_method = "irc_#{server_type.event[code.to_i]}_response".to_sym if !code.to_i.zero? && server_type.event?(code.to_i)
        name                  = arg_array.shift
        meths[numeric_method] = [self, server, name, arg_array, msg]
        meths[readable_method] = [self, server, name, arg_array, msg] if readable_method
        meths[:irc_response] = [self, code, server, name, arg_array, msg]
        return meths
      else
        logger.error "Couldn't parse IRC message: #{comm.inspect}"
        return meths
      end

      if arg_str
        arg_array, msg = split_out_message(arg_str)
      else
        arg_array = Array.new
      end
      command = command.downcase.to_sym

      case command
        when :nick then
          arguments = { nick: arg_array.at(0) }
          # Some IRC servers put the nick in the message field
          unless arguments[:nick]
            arguments[:nick] = msg
            msg              = nil
          end
        when :quit then
          arguments = {}
        when :join then
          arguments = { channel: (msg || arg_array.at(0)) }
          msg       = nil
        when :part then
          arguments = { channel: arg_array.at(0) }
        when :mode then
          arguments = if channel?(arg_array.at(0))
                        { channel: arg_array.at(0) }
                      else
                        { :recipient => arg_array.at(0) }
                      end
          params    = arg_array[2, arg_array.size]
          if params
            params = params.only if params.size == 1
            params = params.presence
          end
          arguments.update(mode: arg_array.at(1), parameter: params)
          # Usermodes stick the mode in the message
          if arguments[:mode].nil? && msg =~ /^[\+\-]\w+$/
            arguments[:mode] = msg
            msg              = nil
          end
        when :topic then
          arguments = { channel: arg_array.at(0), topic: msg }
          msg       = nil
        when :invite then
          arguments = { recipient: arg_array.at(0), channel: msg }
          msg       = nil
        when :kick then
          arguments = { channel: arg_array.at(0), recipient: arg_array.at(1) }
        when :privmsg then
          arguments = if channel?(arg_array.at(0))
                        { channel: arg_array.at(0) }
                      else
                        { :recipient => arg_array.at(0) }
                      end
        when :notice then
          arguments = if channel?(arg_array.at(0))
                        { channel: arg_array.at(0) }
                      else
                        { :recipient => arg_array.at(0) }
                      end
        when :ping then
          arguments = { server: arg_array.at(0) }
        else
          logger.warn "Unknown IRC command #{command.to_s}"
          return
      end
      arguments.update message: msg
      arguments[:channel] = normalized_channel_name(arguments[:channel]) if arguments[:channel]

      method            = "irc_#{command}_event".to_sym
      meths[method]     = [self, sender, arguments]
      meths[:irc_event] = [self, command, sender, arguments]
      return meths
    end

    def build_irc_message(meth, args)
      param_info        = IRC_COMMANDS[meth]
      command_arguments = Array.new
      size              = meth.to_s.size # accumulator of message length

      param_info.each do |param|
        raise ArgumentError, "#{param.name} is required" if args.empty? && param.required
        arg = args.shift.presence
        arg = (param.list && arg.kind_of?(Array)) ? arg.map(&:to_s).join(',') : arg.to_s
        arg = ":#{arg}" if param.colonize
        command_arguments << arg
        size += (arg.size + 1) # include the space
      end
      raise ArgumentError, "Too many parameters" unless args.empty?

      if @when_long == :split
        messages = apply_split_strategy(param_info, command_arguments, size).map { |subargs| "#{meth.to_s.upcase} #{subargs.join(' ')}" }
      elsif @when_long == :cut
        command_arguments = apply_cut_strategy(meth, param_info, command_arguments, size)
        messages          = ["#{meth.to_s.upcase} #{command_arguments.join(' ')}"]
      else
        messages = ["#{meth.to_s.upcase} #{command_arguments.join(' ')}"]
      end

      return messages
    end

    def apply_split_strategy(param_info, args, size)
      # we're only going to split on the last splittable index
      index_to_split = (0..(param_info.size - 1)).select { |index| param_info[index].splittable }.last
      return [args] if index_to_split.nil? # nothing to split, so don't split

      size_of_param = args[index_to_split].size
      size_of_param -= 1 if param_info[index_to_split].colonize # colon doesn't count

      # if we're over maxlength even without the splittable param, then it's hopeless
      size_without_param = size - size_of_param
      return args if size_without_param > @max_message_length

      # otherwise let's word_wrap that parameter and build new param strings
      parts = args[index_to_split].word_wrap(@max_message_length - size_without_param).split("\n")
      return parts.map do |part|
        subargs                 = args.dup
        subargs[index_to_split] = part
        subargs
      end
    end

    def apply_cut_strategy(meth, param_info, args, size)
      while size > @max_message_length
        over                      = size - @max_message_length
        truncatable_param_indexes = (0..(param_info.size - 1)).select { |index| param_info[index].truncatable }

        # start from the last and truncate our way back down
        index_to_truncate         = truncatable_param_indexes.pop
        break if index_to_truncate.nil?
        size_of_param = args[index_to_truncate].size
        size_of_param -= 1 if param_info[index_to_truncate].colonize # colon doesn't count

        if size_of_param <= over
          # if truncating it all the way down wouldn't get us below maxlength,
          # then just remove it
          args[index_to_truncate] = nil
        else
          # otherwise truncate it
          args[index_to_truncate].slice!(size_of_param - over, over + 1)
        end

        size = meth.to_s.size + args.compact.inject(0) { |sum, cur| sum + cur.size + 1 }
      end

      return args
    end

    def split_out_message(arg_str)
      if arg_str.match(/^(.*?):(.*)$/)
        arg_array = $1.strip.words
        msg       = $2
        return arg_array, msg
      else
        # no colon in message
        return arg_str.strip.words, nil
      end
    end

    def post_startup
      privmsg 'NickServ', "IDENTIFY #{options[:password]}" if options[:password]

      @ready_thread     = Thread.new do
        sleep 10
        should_broadcast = false
        @join_mutex.synchronize do
          should_broadcast = true unless @ready
          @ready            = true
          # If irc_join_event set @ready to true, then we know that they have
          # already broadcasted, because those two events are in a critical
          # section. Otherwise, we set ready to true, thus ensuring they won't
          # broadcast, and then broadcast if they haven't already.
          @channels_to_join = nil
        end
        broadcast :stem_ready, self if should_broadcast
      end
      @channels_to_join = @channels
      @channels         = Set.new
      @channels_to_join.each { |chan| join chan, @channel_passwords[chan] }
    end

    def update_names_list(channel, names)
      @chan_mutex.synchronize do
        @updating_channel_members[channel] ||= Hash.new
        names.each do |name|
          @updating_channel_members[channel][server_type.just_nick(name)] = server_type.nick_privilege(name)
        end
      end
    end

    def finish_names_list_update(channel)
      @chan_mutex.synchronize do
        @channel_members[channel] = @updating_channel_members.delete(channel) if @updating_channel_members[channel]
      end
    end

    def drop_channel(channel)
      @channels.delete channel
      @channel_passwords.delete channel
      @channel_members.delete channel
    end

    def privmsgt(*args) # a throttled privmsg
      @messages_queue << args
    end

    def asynchronous_listeners_for_method(meth)
      @listeners.select { |listener| !listener.class.ann(meth, :stem_sync) }
    end

    def synchronous_listeners_for_method(meth)
      @listeners.select { |listener| listener.class.ann(meth, :stem_sync) }
    end
  end
end
