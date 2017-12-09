{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'

require './map.jade'

Template.map.onRendered ->
  Meteor.subscribe 'notes.view', FlowRouter.getParam 'noteId'
  Meteor.subscribe 'notes.children', FlowRouter.getParam 'noteId'
  NProgress.done()
  setTimeout ->
    mymap = L.map('map').setView([51.505, -0.09], 3)
    L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}', {
      attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
      maxZoom: 18,
      id: 'mapbox.streets',
      accessToken: 'pk.eyJ1Ijoibmlja2J1c2V5IiwiYSI6ImNqYXp4c2VvYTBzMnAyd24yMzAwenU5amYifQ.NKY12XE7DfAjEPtyNRCjYw'
    }).addTo(mymap)
    notes = Notes.find
      lat: {$exists:true}
    notes.forEach (note) ->
      marker = L.marker([note.lat, note.lon]).addTo(mymap)
      marker.bindPopup('<a href="'+Meteor.settings.public.url+'/note/'+note._id+'">'+note.title+'</a>')
  , 1000


Template.map.helpers
  childNotes: ->
    Notes.find {
      parent: FlowRouter.getParam('noteId')
    }, sort: rank: 1