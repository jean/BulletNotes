bodyParser = Npm.require( 'body-parser' )

Picker.middleware( bodyParser.json() )
Picker.middleware( bodyParser.urlencoded( { extended: false } ) )

Picker.route '/note/inbox', ( params, request, response, next ) ->
  if request.body.title && request.body.apiKey
    user = Meteor.users.findOne apiKey:request.body.apiKey
    if !user
      response.statusCode = 500
    else
      noteId = Meteor.call 'notes.inbox',
        userId: user._id
        title: request.body.title
        body: request.body.body
      response.setHeader( 'Content-Type', 'application/json' )
      response.statusCode = 200
      response.end( noteId )
  else
    response.statusCode = 500
