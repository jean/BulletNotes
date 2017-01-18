{ Notes } = require '/imports/api/notes/notes.coffee'
{ Meteor } = require 'meteor/meteor'

require './notes.jade'
require '../note/note.coffee'
require '../breadcrumbs/breadcrumbs.coffee'

newNoteText = 'New note...'
Template.notes.onCreated ->
  if Template.currentData().searchTerm
    Meteor.subscribe 'notes.search', Template.currentData().searchTerm
  else if Template.currentData().starred
    Meteor.subscribe 'notes.starred'
  else
    Meteor.subscribe 'notes.all'
  return

#URLs starting with http://, https://, or ftp://
Template.notes.urlPattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim;

#URLs starting with "www." (without // before it, or it'd re-link the ones done above).
Template.notes.urlPattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim

Template.notes.helpers
  focusedNoteTitle: ->
    if Template.currentData().noteId
      note = Notes.findOne(Template.currentData().noteId)
      if note
        Template.notes.formatText note.title
  notes: ->
    if Template.currentData().noteId
      note = Notes.findOne({ parent: Template.currentData().noteId }, sort: rank: 1)
      if (note)
        Session.set 'level', note.level
      Notes.find { parent: Template.currentData().noteId }, sort: rank: 1
    else if Template.currentData().searchTerm
      Session.set 'level', 0
      Notes.find {}
    else
      Session.set 'level', 0
      Notes.find { parent: null }, sort: rank: 1
  newNoteText: ->
    newNoteText
    
Template.notes.events
  'focus #new-note': (event) ->
    if event.currentTarget.innerText == newNoteText
      event.currentTarget.innerText = ''
    return
  'keyup #new-note': (event) ->
    switch event.keyCode
      # Enter
      when 13
        Meteor.call 'notes.insert', event.currentTarget.innerText, null, Template.currentData().noteId, (error) ->
          if error
            alert error.error
          else
            $('#new-note').text ''
          return
      # Escape
      when 27
        $('#new-note').text(newNoteText).blur()
      when 38
        $(event.currentTarget).closest('.note').prev().find('div.title').focus()
    return
  'blur #new-note': (event) ->
    if event.currentTarget.innerText == ''
      $('#new-note').text newNoteText
    return

Template.notes.calculateRank = ->
  levelCount = 0
  maxLevel = 6
  while levelCount < maxLevel
    $('#notes .level-' + levelCount).each (ii, el) ->
      id = Blaze.getData(this)._id
      Meteor.call 'notes.updateRank', id, ii + 1
      return
    levelCount++
  return

Template.notes.formatText = (inputText) ->
  if !inputText
    return
  replacedText = undefined
  replacePattern1 = undefined
  replacePattern2 = undefined
  replacePattern3 = undefined

  replacedText = inputText.replace(Template.notes.urlPattern1, '<a href="$1" target="_blank">$1</a>')
  
  replacedText = replacedText.replace(Template.notes.urlPattern2, '<a href="http://$2" target="_blank">$2</a>')
  #Change email addresses to mailto:: links.
  replacePattern3 = /(([a-zA-Z0-9\-\_\.])+@[a-zA-Z\_]+?(\.[a-zA-Z]{2,6})+)/gim
  replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$1">$1</a>')
  hashtagPattern = /(^|\s|\>)(([#])([a-z\d-]+))/gim

  replacedText = replacedText.replace(searchTerm, '<span class=\'searchResult\'>$&</span>')
  replacedText = replacedText.replace(/&nbsp;/gim, ' ')

  replacedText = replacedText.replace(hashtagPattern, (match, p1, p2, p3, p4, offset, string) ->
    className = p4.toLowerCase()
    ' <a href="/search/%23' + p4 + '" class="tagLink tag-' + className + '">#' + p4 + '</a>'
  )
  namePattern = /(^|\s)(([@])([a-z\d-]+))/gim
  replacedText = replacedText.replace(namePattern, ' <a href="/search/%40$4" class="at-$4">@$4</a>')
  searchTerm = Session.get('searchTerm')
  return replacedText

Template.notes.rendered = ->
  #$( ".selectable" ).selectable()
  $('.sortable').nestedSortable
    handle: '.fa-ellipsis-v'
    items: 'li.note'
    placeholder: 'placeholder'
    forcePlaceholderSize: true
    opacity: .6
    toleranceElement: '> div.noteContainer'
    relocate: ->
      Meteor.call 'notes.updateRanks', $('.sortable').nestedSortable('toArray'), FlowRouter.getParam 'noteId'
      return
