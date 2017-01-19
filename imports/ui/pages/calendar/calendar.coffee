require './calendar.jade'

Template.App_calendar.onRendered ->
  $('#external-events div.external-event').each ->
    # create an Event Object (http://arshaw.com/fullcalendar/docs/event_data/Event_Object/)
    # it doesn't need to have a start or end
    eventObject = title: $.trim($(this).text())
    # store the Event Object in the DOM element so we can get to it later
    $(this).data 'eventObject', eventObject
    # make the event draggable using jQuery UI
    $(this).draggable
      zIndex: 999
      revert: true
      revertDuration: 0
    return

  ### initialize the calendar
   -----------------------------------------------------------------
  ###

  date = new Date
  d = date.getDate()
  m = date.getMonth()
  y = date.getFullYear()
  $('#calendar').fullCalendar
    header:
      left: 'prev,next today'
      center: 'title'
      right: 'month,basicWeek,basicDay'
    editable: true
    droppable: true
    drop: (date, allDay) ->
      # this function is called when something is dropped
      # retrieve the dropped element's stored Event Object
      originalEventObject = $(this).data('eventObject')
      # we need to copy it, so that multiple events don't have a reference to the same object
      copiedEventObject = $.extend({}, originalEventObject)
      # assign it the date that was reported
      copiedEventObject.start = date
      copiedEventObject.allDay = allDay
      # render the event on the calendar
      # the last `true` argument determines if the event "sticks" (http://arshaw.com/fullcalendar/docs/event_rendering/renderEvent/)
      $('#calendar').fullCalendar 'renderEvent', copiedEventObject, true
      # is the "remove after drop" checkbox checked?
      if $('#drop-remove').is(':checked')
        # if so, remove the element from the "Draggable Events" list
        $(this).remove()
      return
    events: [
      {
        title: 'All Day Event'
        start: new Date(y, m, 1)
      }
      {
        title: 'Long Event'
        start: new Date(y, m, d - 5)
        end: new Date(y, m, d - 2)
      }
      {
        id: 999
        title: 'Repeating Event'
        start: new Date(y, m, d - 3, 16, 0)
        allDay: false
      }
      {
        id: 999
        title: 'Repeating Event'
        start: new Date(y, m, d + 4, 16, 0)
        allDay: false
      }
      {
        title: 'Meeting'
        start: new Date(y, m, d, 10, 30)
        allDay: false
      }
      {
        title: 'Lunch'
        start: new Date(y, m, d, 12, 0)
        end: new Date(y, m, d, 14, 0)
        allDay: false
      }
      {
        title: 'Birthday Party'
        start: new Date(y, m, d + 1, 19, 0)
        end: new Date(y, m, d + 1, 22, 30)
        allDay: false
      }
      {
        title: 'Click for Google'
        start: new Date(y, m, 28)
        end: new Date(y, m, 29)
        url: 'http://google.com/'
      }
    ]
  return