{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'
require './calendar.jade'

Template.Notes_calendar.onRendered ->
  Meteor.subscribe 'notes.calendar'
  Meteor.subscribe 'notes.children', FlowRouter.getParam 'noteId'
  NProgress.done()

  Tracker.autorun ->
    events = []

    $('#external-events div.external-event').each ->
      # create an Event Object
      # (http://arshaw.com/fullcalendar/docs/event_data/Event_Object/)
      # it doesn't need to have a start or end
      eventObject = title: $.trim($(this).text())
      console.log (eventObject)
      # store the Event Object in the DOM element so we can get to it later
      $(this).data 'eventObject', eventObject
      # make the event draggable using jQuery UI
      $(this).draggable
        zIndex: 999
        revert: true
        revertDuration: 0

    if FlowRouter.getParam('noteId')
      notes = Notes.find { parent: FlowRouter.getParam('noteId'), due: {$exists: true} }
    else
      notes = Notes.find { due: {$exists: true} }

    notes.forEach (row) ->
      events.push {
        id: row._id
        title: row.title
        start: row.due
        url: '/note/'+row._id
      }

    # $('#calendar').html ''
    console.log "Repaint!"
    $('#calendar').fullCalendar
      header:
        left: 'prev,next today'
        center: 'title'
        right: 'month,basicWeek,basicDay'
      editable: true
      droppable: true
      eventDrop: (date, allDay) ->
        console.log "event drop!"
        console.log date, allDay
        Meteor.call 'notes.setDueDate',
          noteId: date.id
          due: date.start.toDate()
      drop: (date, allDay, event) ->
        Meteor.call 'notes.setDueDate',
          noteId: event.helper[0].dataset.id
          due: date.toDate()
        copiedEventObject = {
          title: event.helper[0].dataset.title
        }
        copiedEventObject.start = date
        copiedEventObject.allDay = allDay
        # the last `true` argument determines if the event "sticks"
        # (http://arshaw.com/fullcalendar/docs/event_rendering/renderEvent/)
        $('#calendar').fullCalendar 'renderEvent', copiedEventObject, true
      events: events

    setTimeout () ->
      $('.fc-today-button').click()
    , 500

Template.Notes_calendar.helpers
  calendarTitle: ->
    note = Notes.findOne({ _id:FlowRouter.getParam('noteId') })
    if note
      note.title
  calendarId: ->
    FlowRouter.getParam 'noteId'
  unscheduledNotes: ->
    Notes.find {
      parent: FlowRouter.getParam('noteId')
      due: {$exists:false}
    }, sort: rank: 1
