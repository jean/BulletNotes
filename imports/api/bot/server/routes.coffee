bodyParser = Npm.require( 'body-parser' )

Picker.middleware( bodyParser.json() )
Picker.middleware( bodyParser.urlencoded( { extended: false } ) )

Picker.route '/bot/chat', ( params, request, response, next ) ->
  if request.body.chat && request.body.apiKey
    Meteor.call 'bot.chat',
      chat: request.body.chat
      apiKey: request.body.apiKey
    , (err, res) ->
      if err
        console.log "Error ", err
        response.statusCode = 301
      else
        response.statusCode = 200
      response.end( res )
  else
    response.statusCode = 500
    response.end()