hubot-mumble
============

Hubot-mumble is a (currently) partially-functional [Hubot](http://hubot.github.com) adapter for the Mumble protocol. 

Hubot-mumble uses a [modified version of the node-mumble](https://github.com/cbpowell/node-mumble/tree/reduction) Node.js library in order to communiate with the Mumble server via the [Mumble protocol](http://mumble.sourceforge.net/Protocol).

Currently, hubot-mumble __DOES__ the following things:

- Fire scripts on user joins
- Fire scripts on user parts
- (Try to) keep track of the current users

It does __NOT__ currently:

- Respond to text seen in the chat (i.e. robot.hear)
- Respond to direct requests in the chat (i.e. robot.respond)
- Respond to direct messages

If you're interested, please submit a pull request to add more functionality! Hubot-mumble was build specifically to support [mumbot-mumble](https://github.com/cbpowell/mumbot-mumble), and so it has the bare minimum of functionality necessary to support that. 
