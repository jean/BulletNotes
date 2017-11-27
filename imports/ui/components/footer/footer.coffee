require './footer.jade'

import introjs from 'intro.js'
import '/node_modules/intro.js/introjs.css';

Template.footer.onCreated ->
  Meteor.call 'version', (err, version) ->
    $('#version').html 'v'+version

Template.footer.onRendered ->
  Headway.init
    selector: "#releaseNotes"
    account:  "J0Xb4J"

Template.footer.events
  'click .introTour': (event, instance) ->
    $(".mdl-layout__content").animate({ scrollTop: 0 }, 200, 'swing', ->
      introjs.introJs().start() 
    )
    

Template.footer.helpers
  year: ->
    moment().format("YYYY")

  totalNotes: ->
    $('#totalNotes').clone().attr('id','totalNotesFall').insertAfter('#totalNotes')
    $('#totalNotesFall').toggle('drop',{direction:'down'}, 1000)
    Counter.get('notes.count.total').toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
