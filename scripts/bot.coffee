module.exports = (robot) ->
  # for slack-node
	token = process.env.HUBOT_SLACK_TOKEN
	Slack = require("slack-node")
	slack = new Slack(token)

  # bot watches any post(raw message)
	robot.adapter.client.on 'raw_message', (msg) ->
    message = JSON.parse(msg)

    if message.type isnt "pong"
      console.log(Object(message))

    # flag if the comment will be posted again or not
    will_post = false

    # message info
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
        ts = message.ts
      else
        user = message.user
        text = message.text
        ts = message.ts

      console.log([channel, ts, user, text, file])

      # search hash tag in the comment
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

      # if hash tag is in comment
      if will_post and user?
        channel = robot.adapter.client.rtm.dataStore.channels[channel]
        user = robot.adapter.client.rtm.dataStore.users[user]

        # for permalink
        data =
          channel: channel.id
          message_ts: ts

        # call back
        apiFunc = (err, res) ->
          if err?
            console.log(err)
          # if file_comment_added
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

          # post comment
          for i in [0..hashtags.length-1]
            robot.adapter.client.web.chat.postMessage(hashtags[i], text, post_data)
          return res

        slack.api "chat.getPermalink", data, apiFunc

