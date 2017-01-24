{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './calendar.jade'

Template.calendar.onRendered ->
  Meteor.subscribe 'notes.calendar'
  Meteor.subscribe 'notes.children', FlowRouter.getParam 'noteId'

  Tracker.autorun ->
    events = []

    $('#external-events div.external-event').each ->
      # create an Event Object
      # (http://arshaw.com/fullcalendar/docs/event_data/Event_Object/)
      # it doesn't need to have a start or end
      eventObject = title: $.trim($(this).text())
      # store the Event Object in the DOM element so we can get to it later
      $(this).data 'eventObject', eventObject
      # make the event draggable using jQuery UI
      $(this).draggable
        zIndex: 999
        revert: true
        revertDuration: 0

    if FlowRouter.getParam('noteId')
      notes = Notes.find { parent: FlowRouter.getParam('noteId') }
    else
      notes = Notes.find { due: {$exists: true} }
    notes.forEach (row) ->
      events.push {
        id: row._id
        title: row.title
        start: row.due
        url: '/note/'+row._id

      }
    $('#calendar').html ''
    $('#calendar').fullCalendar
      header:
        left: 'prev,next today'
        center: 'title'
        right: 'month,basicWeek,basicDay'
      editable: true
      droppable: true
      eventDrop: (date, allDay) ->
        console.log date, allDay
        Meteor.call 'notes.setDueDate', date.id, date.start
      drop: (date, allDay, event) ->
        Meteor.call 'notes.setDueDate', event.target.dataset.id, date
        # this function is called when something is dropped
        # retrieve the dropped element's stored Event Object
        originalEventObject = $(this).data('eventObject')
        # we need to copy it, so that multiple events don't have a reference
        # to the same object
        copiedEventObject = $.extend({}, originalEventObject)
        # assign it the date that was reported
        copiedEventObject.start = date
        copiedEventObject.allDay = allDay
        # render the event on the calendar
        # the last `true` argument determines if the event "sticks"
        # (http://arshaw.com/fullcalendar/docs/event_rendering/renderEvent/)
        $('#calendar').fullCalendar 'renderEvent', copiedEventObject, true
        # is the "remove after drop" checkbox checked?
        $(this).remove()
      events: events

Template.calendar.helpers
  calendarTitle: ->
    note = Notes.findOne({ _id:FlowRouter.getParam('noteId') })
    if note
      note.title
  unscheduledNotes: ->
    Notes.find {
      parent: FlowRouter.getParam('noteId')
      due: {$exists:false}
    }, sort: rank: 1
