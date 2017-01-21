{ Notes } = require '/imports/api/notes/notes.coffee'
{ Meteor } = require 'meteor/meteor'

require './notes.jade'
require '../note/note.coffee'
require '../breadcrumbs/breadcrumbs.coffee'

newNoteText = 'New note...'

#URLs starting with http://, https://, or ftp://
Template.notes.urlPattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim;

#URLs starting with "www." (without // before it, or it'd re-link the ones done above).
Template.notes.urlPattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim

Template.notes.calculateRank = ->
  levelCount = 0
  maxLevel = 6
  while levelCount < maxLevel
    $('#notes .level-' + levelCount).each (ii, el) ->
      id = Blaze.getData(this)._id
      Meteor.call 'notes.updateRank', id, ii + 1
    levelCount++

Template.notes.getProgress = (note) ->
  if !note
    return
  pattern = /#pct-([0-9]+)/gim
  match = pattern.exec note.title
  if match
    match[1]
  else
    # If there is not a defined percent tag (e.g., #pct-20)
    # then calculate the #done rate of notes
    notes = Notes.find({ parent: note._id }, sort: rank: 1)
    total = 0
    done = 0
    notes.forEach (note) ->
      total++
      if note.title
        match = note.title.match Template.note.donePattern
        if match
          done++
    return Math.round((done/total)*100)

Template.notes.getProgressClass = (note) ->
    percent = Template.notes.getProgress note
    if (percent < 25)
      return 'danger'
    else if (percent > 74)
      return 'success'
    else
      return 'warning'

Template.notes.helpers
  progress: ->
    setTimeout ->
      $('[data-toggle="tooltip"]').tooltip()
    , 100
    note = Notes.findOne(Template.currentData().noteId)
    Template.notes.getProgress note
  progressClass: ->
    note = Notes.findOne(Template.currentData().noteId)
    Template.notes.getProgressClass note
  focusedNoteTitle: ->
    if Template.currentData().noteId
      note = Notes.findOne(Template.currentData().noteId)
      if note
        Template.notes.formatText note.title
  notes: ->
    if Template.currentData().searchTerm
      Meteor.subscribe 'notes.search', Template.currentData().searchTerm
    else if Template.currentData().starred
      Meteor.subscribe 'notes.starred'
    else
      Meteor.subscribe 'notes.view', Template.currentData().noteId, FlowRouter.getParam 'shareKey'
      Meteor.subscribe 'notes.children', Template.currentData().noteId, FlowRouter.getParam 'shareKey'
    Session.set 'searchTerm', Template.currentData().searchTerm

    if Template.currentData().noteId
      note = Notes.findOne({ parent: Template.currentData().noteId }, sort: rank: 1)
      if (note)
        Session.set 'level', note.level
      # else
      #   $.gritter.add
      #     title: 'Not found'
      #     text: 'Note not found.'
      #   FlowRouter.go '/'
      Notes.find { parent: Template.currentData().noteId }, sort: rank: 1
    else if Template.currentData().searchTerm
      Session.set 'level', 0
      Notes.search Template.currentData().searchTerm
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
        Meteor.call 'notes.insert', event.currentTarget.innerText, null, Template.currentData().noteId, FlowRouter.getParam('shareKey'), (error) ->
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

Template.notes.formatText = (inputText) ->
  if !inputText
    return
  replacedText = undefined
  replacePattern1 = undefined
  replacePattern2 = undefined
  replacePattern3 = undefined

  replacedText = inputText.replace(Template.notes.urlPattern1, '<a href="$1" target="_blank" class="previewLink">$1</a>')
  
  replacedText = replacedText.replace(Template.notes.urlPattern2, '<a href="http://$2" target="_blank" class="previewLink">$2</a>')
  #Change email addresses to mailto:: links.
  replacePattern3 = /(([a-zA-Z0-9\-\_\.])+@[a-zA-Z\_]+?(\.[a-zA-Z]{2,6})+)/gim
  replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$1">$1</a>')
  hashtagPattern = /(^|\s|\>)(([#])([a-z\d-]+))/gim
  searchTerm = Session.get('searchTerm')
  replacedText = replacedText.replace(searchTerm, '<span class=\'searchResult\'>$&</span>')
  replacedText = replacedText.replace(/&nbsp;/gim, ' ')

  replacedText = replacedText.replace(hashtagPattern, (match, p1, p2, p3, p4, offset, string) ->
    className = p4.toLowerCase()
    ' <a href="/search/%23' + p4 + '" class="tagLink tag-' + className + '">#' + p4 + '</a>'
  )
  namePattern = /(^|\s)(([@])([a-z\d-]+))/gim
  replacedText = replacedText.replace(namePattern, ' <a href="/search/%40$4" class="at-$4">@$4</a>')

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
      Meteor.call 'notes.updateRanks', $('.sortable').nestedSortable('toArray'), FlowRouter.getParam('noteId'), FlowRouter.getParam('shareKey')
