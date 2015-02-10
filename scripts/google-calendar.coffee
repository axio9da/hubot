# Description:
#   google calendar for hubot
# Commands:
#   hubot cal

requestWithJWT = require('google-oauth-jwt').requestWithJWT()
moment         = require('moment-timezone')
_              = require('underscore')

module.exports = (robot) ->

  robot.respond /cal$/i, (msg) ->
    msg.send "Getting our schedules..."
    try
      d = new Date()
      getCalendarEvents d, (str) ->
        msg.send str
    catch e
      msg.send "exception: #{e}"

  request = (opt, onSuccess, onError) ->
    params =
      jwt:
        email: process.env.HUBOT_GOOGLE_CALENDAR_EMAIL
        keyFile: process.env.HUBOT_GOOGLE_CALENDAR_KEYFILE
        scopes: ['https://www.googleapis.com/auth/calendar.readonly']

    _.extend(params, opt)

    requestWithJWT(params, (err, res, body) ->
      if err
        onError(err)
      else
        if res.statusCode != 200
          onError "status code is #{res.statusCode}"
          return

        onSuccess JSON.parse(body)
    )

  formatEvent = (event) ->
    strs = []
    strs.push event.summary
    if event.start
      if event.start.date
        strs.push "Start: " + event.start.date
      else if event.start.dateTime
        strs.push "Start: " + event.start.dateTime

    if event.end
      if event.end.date
        strs.push "Close: " + event.end.date
      else if event.end.dateTime
        strs.push "Close: " + event.end.dateTime

    if event.location
      strs.push "場所: " + event.location

    if event.description
      strs.push "詳細: " + event.describe

    strs.join("\n") + "\n"


  getCalendarEvents = (baseDate, cb) ->
    onError = (err) ->
      cb "receive err: #{err}"

    request(
      { url: 'https://www.googleapis.com/calendar/v3/users/me/calendarList' }
      (data) ->
        timeMin = new Date(baseDate.getTime())
        timeMin.setHours 0, 0, 0
        baseDate.setDate(baseDate.getDate() + 7)
        timeMax = new Date(baseDate.getTime())
        timeMax.setHours 23, 59, 59
        for i, item of data.items
          do (item) ->
            request(
              {
                url: "https://www.googleapis.com/calendar/v3/calendars/#{item.id}/events"
                qs:
                  timeMin: moment(timeMin).tz(item.timeZone).format()
                  timeMax: moment(timeMax).tz(item.timeZone).format()
                  orderBy: 'startTime'
                  singleEvents: true
                  timeZone: item.timeZone
              }
              (data) ->
                strs = [item.id + "の" + (timeMin.getMonth() + 1) + "/" + timeMin.getDate() + " - " + (timeMax.getMonth() + 1) + "/" + timeMax.getDate() + "の予定(" + data.items.length + "件)"]
                for i, item of data.items
                  if item.end.date
                    d = new Date(item.end.date)
                    d.setHours 0, 0, 0
                    if d < timeMin
                      continue
                  strs.push (parseInt(i,10)+1) + ": " + formatEvent(item)
                cb strs.join("\n")
              onError
            )
      onError
    )

