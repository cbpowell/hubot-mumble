# Hubot dependencies
{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, Response} = require 'hubot'

Mumbler = require 'mumble'
fs = require 'fs'

class MumbleBot extends Adapter
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


	
	checkCanStart: ->
    if not process.env.HUBOT_MUMBLE_NICK or @robot.name
      throw new Error("HUBOT_MUMBLE_NICK is not defined; try: export HUBOT_MUMBLE_NICK='mybot'")
    else if not process.env.HUBOT_MUMBLE_PATH
      throw new Error("HUBOT_MUMBLE_PATH is not defined; try: export HUBOT_MUMBLE_PATH='mumble://path.to/server'")
    else if not process.env.HUBOT_MUMBLE_CERTPATH)
      throw new Error("HUBOT_MUMBLE_CERTPATH is not defined: try: export HUBOT_MUMBLE_CERTPATH='/path/to/cert'")
	###
  
  userJoined: (user, channel) ->
    console.log "User update:", user
    mumUser = @robot.brain.userForId user.session
    if channel.name is mumUser.room
      return
    
    mumUser.name = user.name
    mumUser.room = channel.name
    @receive new EnterMessage(mumUser)
      
  userDeparted: (user) ->
    console.log "User removed:", user
    mumUser = @robot.brain.userForId user.session
    mumUser.room = null
    @receive new LeaveMessage(mumUser)

  run: ->
    self = @
    
    #do @checkCanStart
      
    @robot.name = process.env.HUBOT_MUMBLE_NICK
    
    options =
      nick:     process.env.HUBOT_MUMBLE_NICK or @robot.name
      path:     process.env.HUBOT_MUMBLE_PATH
      password: process.env.HUBOT_MUMBLE_PASSWORD
      cert:			fs.readFileSync(process.env.HUBOT_MUMBLE_CERTPATH)
      debug:    process.env.HUBOT_IRC_DEBUG
    
    mumbleOptions =
      pfx:  options.cert
    
    kickoff = new Mumbler.connect options.path, mumbleOptions, (error, connection) ->
      throw new Error(error) if error
			
      # Authenticate and initialize
      connection.authenticate options.nick, options.password
      
      connection.on "initialized", ->
        self.emit "connected"
        console.log "Connection initialized"
			
      connection.on "user-update", (user) ->
        channel = connection.channels[user.channelId]
        self.userJoined user, channel
      
      connection.on "user-remove", (user) ->
        self.userDeparted user
    
exports.use = (robot) ->
  new MumbleBot robot
