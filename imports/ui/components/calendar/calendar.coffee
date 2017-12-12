{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'
{ Files } = require '/imports/api/files/files.coffee'
require './calendar.jade'

Template.calendar.onCreated ->
  @state = new ReactiveDict()

  @state.setDefault
    eventSidebar: true

Template.calendar.onRendered ->
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
      Meteor.call 'notes.setDueDate',
        noteId: event.id
        date: event.start.format('YYYY-MM-DD')

    drop: (date, allDay, event) ->
      Meteor.call 'notes.setDueDate',
        noteId: event.helper[0].dataset.id
        date: date.format('YYYY-MM-DD')
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
      # store the Event Object in the DOM element so we can get to it later
      $(this).data 'eventObject', eventObject
      # make the event draggable using jQuery UI
      $(this).draggable
        zIndex: 999
        revert: true
        revertDuration: 0

    if FlowRouter.getParam('noteId')
      notes = Notes.find { parent: FlowRouter.getParam('noteId'), date: {$exists: true} }
    else
      notes = Notes.find { date: {$exists: true} }

    $('#calendar').fullCalendar 'removeEvents'
    notes.forEach (row) ->
      Meteor.subscribe 'files.note', row._id
      file = Files.findOne { noteId: row._id }

      event = {
        id: row._id
        title: row.title.substr(0,50)
        start: row.date
        url: '/note/'+row._id
        allDay: true
        borderColor: ""
      }
      $('#calendar').fullCalendar 'renderEvent', event, true
      events.push event

      if file
        date = moment.utc(row.date).format('YYYY-MM-DD')
        $('.fc-day[data-date="'+date+'"]').css('background-image', 'url(' + file.data + ')');

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
      date: {$exists:false}
    }, sort: rank: 1

  trimTitle: (title) ->
    if title.length > 50
      title.substr(0,50)+"..."
    else
      title

  photoModeClass: ->
    if Template.instance().state.get 'photoMode'
      'mdl-button--colored'

  calendarClass: ->
    if Template.instance().state.get 'photoMode'
      'photoMode'

  calendarCellClass: ->
    if Template.instance().state.get 'eventSidebar'
      'mdl-cell--12-col'
    else
      'mdl-cell--8-col'

  externalEventsCellClass: ->
    if Template.instance().state.get 'eventSidebar'
      'mdl-cell--12-col'
    else
      'mdl-cell--4-col'

  sidebarClass: ->
    if Template.instance().state.get 'eventSidebar'
      'mdl-button--colored'

  sidebarIcon: ->
    if Template.instance().state.get 'eventSidebar'
      'keyboard_arrow_left'
    else
      'keyboard_arrow_right'

Template.calendar.events
  'click #togglePhotoMode': (event, instance) ->
    event.preventDefault()
    instance.state.set('photoMode',!instance.state.get('photoMode'))

  'click #toggleSidebar': (event, instance) ->
    event.preventDefault()
    instance.state.set('eventSidebar',!instance.state.get('eventSidebar'))
    setTimeout ->
      $('#calendar').fullCalendar('option', 'aspectRatio', 1.35)
    , 100
