pjson = require('/package.json')
{ Meteor } = require 'meteor/meteor'

Meteor.methods
  'version': (version) ->
    pjson.version

  'summary': (email) ->
    SSR.compileTemplate( 'Email_summary', Assets.getText( 'email/summary.html' ) );
    html = SSR.render( 'Email_summary', { site_url: Meteor.absoluteUrl() } )
    Email.send({  
      to: email,
      from: "BulletNotes.io <admin@bulletnotes.io>",
      subject: "Daily Activity Summary",
      html: html
    });
