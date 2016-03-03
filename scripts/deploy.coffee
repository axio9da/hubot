module.exports = (robot) ->
  github = require("githubot")(robot)
  unless (url_api_base = process.env.HUBOT_GITHUB_API)?
          url_api_base = "https://api.github.com"

  _getDate = ->
    theDate = new Date
    yyyy = theDate.getFullYear()
    mm = theDate.getMonth()+1 #January is 0!
    if mm < 10
      mm = "0" + mm
    dd = theDate.getDate()
    if dd < 10
      dd = "0" + dd
    yyyy + "." + mm + "." + dd

  robot.respond /([-_\.0-9a-zA-Z]+) deploy ([-_\.a-zA-z0-9\/]+)? into ([-_\.a-zA-z0-9\/]+)$/i, (msg)->
    repo = msg.match[1]
    head = msg.match[2] || "master"
    base = msg.match[3]
    environment = msg.match[3]

    url = "#{url_api_base}/repos/axio9da/#{repo}/pulls"

    account_name = msg.envelope.user.name || "anonymous"
    channel_name = msg.envelope.room || "anonymous"

    title = "#{_getDate()} #{environment} deployment by #{account_name}"
    circleCIUrl = "https://circleci.com/gh/axio9da/#{repo}/tree/#{encodeURIComponent(base)}" #CircleCIのURL

    body = """
      ・Created By #{account_name} on #{channel_name} Channel
      ・Circle CI build status can be shown: #{circleCIUrl}
    """

    data = {
      "title": title
      "body": body
      "head": head
      "base": base
    }

    github.post url, data, (pull) ->
      msg.send "プルリク作りました " + pull.html_url
