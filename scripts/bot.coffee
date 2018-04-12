module.exports = (robot) ->
	token = process.env.HUBOT_SLACK_TOKEN
	Slack = require("slack-node")
	slack = new Slack(token)

#	robot.hear /#(_[0-9a-zA-Z\-_]+)/i, (msg) ->
#
#		user = msg.message.user
#		channel = robot.adapter.client.rtm.dataStore.getChannelByName(msg.match[1])
#		data =
#			channel: msg.message.room
#			message_ts: msg.message.id
#		if msg.message.room == channel.id
#			return
#
#		console.log Object(user)
#
#		apiFunc = (err, res) ->
#			console.log(err)
#			text = (msg.message.text.replace "##{msg.match[1]}", '').trim()
#			username = user.real_name
#			icon_url = user.profile.image_72
#			attachments = JSON.stringify [
#				title: "in ##{robot.adapter.client.rtm.dataStore.channels[msg.message.room].name}"
#				title_link: res.permalink
#			]
#			robot.adapter.client.web.chat.postMessage(channel.id, text, {username: username, icon_url: icon_url, attachments: attachments})
#		slack.api "chat.getPermalink", data, apiFunc

	robot.adapter.client.on 'raw_message', (msg) ->
    message = JSON.parse(msg)
    if message.type isnt "pong"
      console.log(Object(message))

    will_post = false

    if message.type is "message" and message.subtype isnt "message_replied"
      channel = message.channel
      if message.subtype is "message_changed"
        user = message.message.user
        text = message.message.text
        ts = message.message.ts
      else if message.subtype is "file_comment"
        user = message.comment.user
        text = message.comment.comment
        file = message.file.permalink
        file_name = message.file.name
        file_thumb = message.file.thumb_360
        ts = message.ts
      else
        user = message.user
        text = message.text
        ts = message.ts

      console.log([channel, ts, user, text, file])

      hashtag_re = /<#(C[0-9A-Z]+)\|_[0-9a-zA-Z\-_]+>/g
      hashtags = []
      while (hashtag = hashtag_re.exec(text))?
        hashtags.push(hashtag[1])

      if hashtags.length > 0
        will_post = true
        for i in [0..(hashtags.length-1)]
          console.log("bot will post to #" + hashtags[i])
        text = text.replace(/<#[0-9A-Z]+\|(_[0-9a-zA-Z\-_]+)>/g, '').trim()
        console.log(text)

      if will_post and user?
        channel = robot.adapter.client.rtm.dataStore.channels[channel]
        user = robot.adapter.client.rtm.dataStore.users[user]

        data =
          channel: channel.id
          message_ts: ts

        apiFunc = (err, res) ->
          if err?
            console.log(err)
          if file?
            post_data =
              username: user.real_name
              icon_url: user.profile.image_72
              attachments: JSON.stringify [
                {
                  title: "in ##{channel.name}"
                  title_link: res.permalink
                },
                {
                  title: "on " + file_name
                  image_url: file
                }
                ]
          else
            post_data =
              username: user.real_name
              icon_url: user.profile.image_72
              attachments: JSON.stringify [
                {
                  title: "in ##{channel.name}"
                  title_link: res.permalink
                }
              ]

          for i in [0..hashtags.length-1]
            robot.adapter.client.web.chat.postMessage(hashtags[i], text, post_data)
          return res
        slack.api "chat.getPermalink", data, apiFunc

  # robot.hear /badger/i, (res) ->
  #   res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  #
  # robot.respond /open the (.*) doors/i, (res) ->
  #   doorType = res.match[1]
  #   if doorType is "pod bay"
  #     res.reply "I'm afraid I can't let you do that."
  #   else
  #     res.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (res) ->
  #   res.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (res) ->
  #   res.send res.random lulz
  #
  # robot.topic (res) ->
  #   res.send "#{res.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (res) ->
  #   res.send res.random enterReplies
  # robot.leave (res) ->
  #   res.send res.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (res) ->
  #   unless answer?
  #     res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   res.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (res) ->
  #   setTimeout () ->
  #     res.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   res.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     res.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, res) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if res?
  #     res.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (res) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     res.reply "I'm too fizzy.."
  #
  #   else
  #     res.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (res) ->
  #   robot.brain.set 'totalSodas', 0
  #   res.reply 'zzzzz'
