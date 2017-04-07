{ Files } = require '/imports/api/files/files.coffee'
bodyParser = Npm.require( 'body-parser' )

Picker.middleware( bodyParser.json() )
Picker.middleware( bodyParser.urlencoded( { extended: false } ) )

Picker.route '/file/download/:fileId', ( params, request, response, next ) ->
  console.log params['fileId']
  if params['fileId']
    file = Files.findOne params['fileId']
    response.setHeader( 'Content-Type', 'application/octet-stream' )
    response.statusCode = 200
    response.end( file.data )
  else
    response.statusCode = 500
