# Hubot dependencies
{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, Response} = require 'hubot'

# node-mumble library
Mumble = require 'node-mumble'
fs = require 'fs'

class Mumble extends Adapter
  ### 
	send: (envelope, strings...) ->
    target = @_getTargetFromEnvelope envelope

    unless target
      return console.log "ERROR: Not sure who to send to. envelope=", envelope

    for str in strings
      @bot.say target, str
  emote: (envelope, strings...) ->
    # Use @notice if SEND_NOTICE_MODE is set
    return @notice envelope, strings if process.env.HUBOT_IRC_SEND_NOTICE_MODE?

    target = @_getTargetFromEnvelope envelope

    unless target
      return console.log "ERROR: Not sure who to send to. envelope=", envelope

    for str in strings
      @bot.action target, str

  notice: (envelope, strings...) ->
    target = @_getTargetFromEnvelope envelope

    unless target
      return console.log "Notice: no target found", envelope

    # Flatten out strings from send
    flattened = []
    for str in strings
      if Array.isArray str
        flattened = flattened.concat str
      else
        flattened.push str

    for str in flattened
      if not str?
        continue

      @bot.notice target, str

  reply: (envelope, strings...) ->
    for str in strings
      @send envelope.user, "#{envelope.user.name}: #{str}"

  join: (channel) ->
    self = @
    @bot.join channel, () ->
      console.log('joined %s', channel)

      self.receive new EnterMessage(null)

  part: (channel) ->
    self = @
    @bot.part channel, () ->
      console.log('left %s', channel)

      self.receive new LeaveMessage(null)

  getUserFromName: (name) ->
    return @robot.brain.userForName(name) if @robot.brain?.userForName?

    return @userForName name

  getUserFromId: (id) ->
    return @robot.brain.userForId(id) if @robot.brain?.userForId?

    return @userForId id

  createUser: (channel, from) ->
    user = @getUserFromName from
    unless user?
      id = new Date().getTime().toString()
      user = @getUserFromId id
      user.name = from

    if channel.match(/^[&#]/)
      user.room = channel
    else
      user.room = null
    user

  kick: (channel, client, message) ->
    @bot.emit 'raw',
      command: 'KICK'
      nick: process.env.HUBOT_IRC_NICK
      args: [ channel, client, message ]

  command: (command, strings...) ->
    @bot.send command, strings...


  ###
	
	checkCanStart: ->
    if not process.env.HUBOT_IRC_NICK and not @robot.name
      throw new Error("HUBOT_IRC_NICK is not defined; try: export HUBOT_IRC_NICK='mybot'")
    else if not process.env.HUBOT_IRC_ROOMS
      throw new Error("HUBOT_IRC_ROOMS is not defined; try: export HUBOT_IRC_ROOMS='#myroom'")
    else if not process.env.HUBOT_IRC_SERVER
      throw new Error("HUBOT_IRC_SERVER is not defined: try: export HUBOT_IRC_SERVER='irc.myserver.com'")

  run: ->
    self = @

    # do @checkCanStart

    options =
      nick:     process.env.HUBOT_MUMBLE_NICK or @robot.name
      path:     process.env.HUBOT_MUMBLE_PATH
      password: process.env.HUBOT_MUMBLE_PASSWORD
      cert:			fs.readFileSync(process.env.HUBOT_MUMBLE_CERTPATH)
      debug:    process.env.HUBOT_IRC_DEBUG?
			
		mumbleOptions =
			pfx:			options.cert
	  
    #@robot.name = options.nick
	  
    #bot = new Mumble.connect options.path, mumbleOptions, (error, connection) ->
		new Mumble.connect options.path, mumbleOptions, (error, connection) ->
			throw new Error(error) if error
			
			# Authenticate and initialize
			connection.authenticate options.nick, options.passwordconnection.on "initialized", ->
				output = connection
				console.log "Connection initialized"
				
			connection.on "user-update", (user) ->
				console.log "User update:", user
				console.log "Connection:", output
				
			connection.on "user-remove", (user) ->
				console.log "User removed:", user

    @bot = bot

    self.emit "connected"

  _getTargetFromEnvelope: (envelope) ->
    user = null
    room = null
    target = null

    # as of hubot 2.4.2, the first param to send() is an object with 'user'
    # and 'room' data inside. detect the old style here.
    if envelope.reply_to
      user = envelope
    else
      # expand envelope
      user = envelope.user
      room = envelope.room

    if user
      # most common case - we're replying to a user in a room
      if user.room
        target = user.room
      # reply directly
      else if user.name
        target = user.name
      # replying to pm
      else if user.reply_to
        target = user.reply_to
      # allows user to be an id string
      else if user.search?(/@/) != -1
        target = user
    else if room
      # this will happen if someone uses robot.messageRoom(jid, ...)
      target = room

    target




exports.use = (robot) ->
  new Mumble robot
