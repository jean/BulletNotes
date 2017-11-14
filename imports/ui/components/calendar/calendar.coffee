{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'
require './calendar.jade'

Template.calendar.onRendered ->
  Meteor.subscribe 'notes.calendar'
  Meteor.subscribe 'notes.children', FlowRouter.getParam 'noteId'
  NProgress.done()

  this.calendar = $('#calendar').fullCalendar
    header:
      left: 'prev,next today'
      center: 'title'
      right: 'month,basicWeek,basicDay'
    editable: true
    droppable: true
    timezone: "UTC"
    eventDrop: (event) ->
      console.log "event move!"
      console.log event
      Meteor.call 'notes.setDueDate',
        noteId: event.id
        due: event.start.format('YYYY-MM-DD')

    drop: (date, allDay, event) ->
      console.log "event drop!"
      console.log date
      console.log date, allDay, event
      Meteor.call 'notes.setDueDate',
        noteId: event.helper[0].dataset.id
        due: date.format('YYYY-MM-DD')
      copiedEventObject = {
        title: event.helper[0].innerText
      }
      copiedEventObject.start = date
      copiedEventObject.allDay = allDay
      # the last `true` argument determines if the event "sticks"
      # (http://arshaw.com/fullcalendar/docs/event_rendering/renderEvent/)
      $('#calendar').fullCalendar 'renderEvent', copiedEventObject, true

  that = this
  Tracker.autorun ->
    events = []

    $('#external-events .external-event').each ->
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

    $('#calendar').fullCalendar 'removeEvents'
    notes.forEach (row) ->
      event = {
        id: row._id
        title: row.title.substr(0,50)
        start: row.due
        url: '/note/'+row._id
        allDay: true
        borderColor: ""
      }
      $('#calendar').fullCalendar 'renderEvent', event, true 
      events.push event

    console.log "Repaint!", events
    # $('#calendar').fullCalendar 'renderEvents', events, true

    setTimeout () ->
      $('.fc-today-button').click()
    , 500

Template.calendar.helpers
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

  trimTitle: (title) ->
    if title.length > 50
      title.substr(0,50)+"..."
    else
      title