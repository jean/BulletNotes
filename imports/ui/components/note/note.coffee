{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '/imports/api/notes/notes.coffee'
{ Files } = require '/imports/api/files/files.coffee'

require './note.jade'
require '/imports/ui/components/share/share.coffee'
require '/imports/ui/components/file/file.coffee'

{ noteRenderHold } = require '../../launch-screen.js'
{ displayError } = require '../../lib/errors.js'

import {
  favorite
} from '/imports/api/notes/methods.coffee'

import {
  upload
} from '/imports/api/files/methods.coffee'


Template.note.previewXOffset = 10
Template.note.previewYOffset = 10

Template.note.encodeImageFileAsURL = (cb,file) ->
    reader = new FileReader

    reader.onloadend = ->
      cb reader.result

    reader.readAsDataURL file

Template.note.isValidImageUrl = (url, callback) ->
  $ '<img>',
    src: url
    error: ->
      callback url, false
    load: ->
      callback url, true

Template.note.onRendered ->
  note = this
  Tracker.autorun ->
    newNote = Notes.findOne note.data._id
    if newNote
      $(note.firstNode).find('.title').first().html(
        Template.notes.formatText newNote.title
      )
      if newNote.body
        $(note.firstNode).find('.body').first().show().html(
          Template.notes.formatText newNote.body
        )

Template.note.helpers
  files: () ->
    Meteor.subscribe 'files.note', @_id
    Files.find { noteId: @_id }

  children: () ->
    Meteor.subscribe 'notes.children',
      @_id,
      FlowRouter.getParam 'shareKey'

    if @showChildren || Session.get 'expand_'+@_id
      Notes.find { parent: @_id }, sort: {rank: 1}

  editingClass: (editing) ->
    editing and 'editing'

  expandClass: () ->
    if @children > 0
      if @showChildren || Session.get('expand_'+@_id)
        'glyphicon glyphicon-minus'
      else
        'glyphicon glyphicon-plus'

  className: ->
    className = "note"
    if @title
      tags = @title.match(/#\w+/g)
      if tags
        tags.forEach (tag) ->
          className = className + ' tag-' + tag.substr(1).toLowerCase()
    if !@showChildren && @children > 0
      className = className + ' hasHiddenChildren'
    if @shared
      className = className + ' shared'
    className

  userOwnsNote: ->
    Meteor.userId() == @owner

  favoriteClass: ->
    if @favorite
      'favorited'

  progress: ->
    setTimeout ->
      $('[data-toggle="tooltip"]').tooltip()
    , 100
    @progress

  progressClass: ->
    Template.notes.getProgressClass this

Template.note.events
  'click .title a': (event) ->
    if !$(event.target).hasClass('tagLink') && !$(event.target).hasClass('atLink')
      window.open(event.target.href)

  'click .favorite': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    favorite.call
      noteId: instance.data._id

  'click .duplicate': (event) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    Meteor.call 'notes.duplicate', @_id

  'click a.delete': (event) ->
    event.preventDefault()
    $(event.currentTarget).closest('.note').remove()
    Meteor.call 'notes.remove',
      noteId: @_id
      shareKey: FlowRouter.getParam 'shareKey'
    , (err, res) ->
      if err
        window.location = window.location

  'mouseover .tagLink': (event) ->
    notes = Notes.search event.target.innerHTML
    $('#tagSearchPreview').html('');
    notes.forEach (note) ->
      $('#tagSearchPreview').append('<li><a class="previewTagLink">'+Template.notes.formatText(note.title,false)+'</a></li>')
        .css('top', event.pageY - Template.note.previewXOffset + 'px')
        .css('left', event.pageX + Template.note.previewYOffset + 'px')
        .show()

  'mousemove .tagLink': (event) ->
    $('#tagSearchPreview').css('top', event.pageY - Template.note.previewXOffset + 'px')
      .css 'left', event.pageX + Template.note.previewYOffset + 'px'

  'mouseleave .tagLink': (event) ->
    $('#tagSearchPreview').hide()

  'mouseover .previewLink': (event) ->
    @t = @title
    @title = ''
    c = if @t != '' then '<br/>' + @t else ''
    url = event.currentTarget.href
    Template.note.isValidImageUrl url, (url, valid) ->
      if valid
        $('body').append '<p id=\'preview\'><a href=\'' +
          url + '\' target=\'_blank\'><img src=\'' + url +
          '\' alt=\'Image preview\' />' + c + '</p>'
        $('#preview').css('top', event.pageY - Template.note.previewXOffset + 'px')
          .css('left', event.pageX + Template.note.previewYOffset + 'px')
          .fadeIn 'fast'
        $('#preview img').mouseleave ->
          $('#preview').remove()

  'mousemove .previewLink': (event) ->
    $('#preview').css('top', event.pageY - Template.note.previewXOffset + 'px')
      .css 'left', event.pageX + Template.note.previewYOffset + 'px'

  'mouseleave .previewLink': (event) ->
    $('#preview img').attr('src','')
    $('#preview').remove()

  'keydown .title': (event, instance) ->
    note = this
    event.stopImmediatePropagation()
    switch event.keyCode
      # Enter
      when 13
        event.preventDefault()
        if event.shiftKey
          # Edit the body
          $(event.target).siblings('.body').fadeIn().focus()
        else
          # Chop the text in half at the cursor
          # put what's on the left in a note on top
          # put what's to the right in a note below
          console.log window.getSelection().anchorOffset
          console.log event
          position = event.target.selectionStart
          text = event.target.innerHTML
          topNote = text.substr(0, position)
          bottomNote = text.substr(position)
          # Create a new note below the current.
          if topNote != Template.note.stripTags(note.title)
            Meteor.call 'notes.updateTitle', {
              noteId: note._id
              title: topNote
              shareKey: FlowRouter.getParam('shareKey')
            }
          Meteor.call 'notes.insert', {
            title: ''
            rank: note.rank + 1
            parent: note.parent
            shareKey: FlowRouter.getParam('shareKey')
          }
          setTimeout (->
            $(event.target).closest('.note-item')
              .next().find('.title').focus()
          ), 50
      # Tab
      when 9
        event.preventDefault()
        Session.set 'indenting', true
        # First save the title in case it was changed.
        title = Template.note.stripTags(event.target.innerHTML)
        if title != @title
          Meteor.call 'notes.updateTitle',
            noteId: @_id
            title: title

            # FlowRouter.getParam 'shareKey'
        parent_id = Blaze.getData(
          $(event.currentTarget).closest('.note-item').prev().get(0)
        )._id
        if event.shiftKey
          Meteor.call 'notes.outdent', {
            noteId: @_id
            shareKey: FlowRouter.getParam 'shareKey'
          }
        else
          childCount = Notes.find({parent: parent_id}).count()
          Meteor.call 'notes.makeChild', {
            noteId: @_id
            parent: parent_id
            rank: (childCount*2)+1
            shareKey: FlowRouter.getParam 'shareKey'
          }
      # Backspace / delete
      when 8
        if event.currentTarget.innerText.trim().length == 0
          $(event.currentTarget).closest('.note-item').prev().find('.title').focus()
          $(event.currentTarget).closest('.note-item').fadeOut()
          Meteor.call 'notes.remove',
            noteId: @_id
            FlowRouter.getParam 'shareKey'
        if window.getSelection().toString() == ''
          position = event.target.selectionStart
          if position == 0
            # We're at the start of the note,
            # add this to the note above, and remove it.
            console.log event.target.value
            prev = $(event.currentTarget).closest('.note-item').prev()
            console.log prev
            prevNote = Blaze.getData(prev.get(0))
            console.log prevNote
            note = this
            console.log note
            Meteor.call 'notes.updateTitle',
              prevNote._id,
              prevNote.title + event.target.value,
              FlowRouter.getParam 'shareKey',
              (err, res) ->
                Meteor.call 'notes.remove',
                  note._id,
                  FlowRouter.getParam 'shareKey',
                  (err, res) ->
                    # Moves the caret to the correct position
                    prev.find('div.title').focus()
      # Up
      when 38
        # Command is held
        if event.metaKey
          Template.note.toggleChildren(instance)
        else
          if $(event.currentTarget).closest('.note-item').prev().length
            $(event.currentTarget).closest('.note-item')
              .prev().find('div.title').focus()
          else
            # There is no previous note in the current sub list, go up a note.
            $(event.currentTarget).closest('.note-item')
              .parentsUntil('.note-item').siblings('.noteContainer')
              .find('div.title').focus()
      # Down
      when 40
        if event.metaKey
          Template.note.toggleChildren(instance)
        else
          # Go to a child note if available
          note = $(event.currentTarget).closest('.note-item')
            .find('ol .note').first()
          if !note.length
            # If not, get the next note on the same level
            note = $(event.currentTarget).closest('.note-item').next()
          if !note.length
            # Nothing there, keep going up levels.
            count = 0
            searchNote = $(event.currentTarget).parent().closest('.note-item')
            while note.length < 1 && count < 10
              note = searchNote.next()
              if !note.length
                searchNote = searchNote.parent().closest('.note-item')
                count++
          if note.length
            note.find('div.title').first().focus()
          else
            $('#new-note').focus()
      # Escape
      when 27
        $(event.currentTarget).html Session.get 'preEdit'
        $(event.currentTarget).blur()
        window.getSelection().removeAllRanges()

  'focus div.title': (event, instance) ->
    event.stopImmediatePropagation()
    Session.set 'preEdit', @title
    Meteor.call 'notes.focus',
      noteId: @_id

  'blur .title': (event, instance) ->
    that = this
    event.stopPropagation()
    # If we blurred because we hit tab and are causing an indent
    # don't save the title here, it was already saved with the
    # indent event.
    if Session.get 'indenting'
      Session.set 'indenting', false
      return

    title = Template.note.stripTags(event.target.innerHTML)
    if title != Template.note.stripTags(@title)
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data._id
        title: title
        shareKey: FlowRouter.getParam 'shareKey'
      }, (err, res) ->
        that.title = title
        $(event.target).html Template.notes.formatText title

  'blur .body': (event, instance) ->
    event.stopPropagation()
    that = this
    body = Template.note.stripTags(event.target.innerHTML)
    if body != Template.note.stripTags(@body)
      Meteor.call 'notes.updateBody', {
        noteId: instance.data._id
        body: body
        shareKey: FlowRouter.getParam 'shareKey'
      }, (err, res) ->
        that.body = body
        $(event.target).html Template.notes.formatText body
    if !body
      $(event.target).fadeOut()

  'click .expand': (event, instance) ->
    event.stopImmediatePropagation()
    event.preventDefault()
    Template.note.toggleChildren(instance)

  'dragover .title, dragover .filesContainer': (event, instance) ->
    $(event.currentTarget).closest('.noteContainer').addClass 'dragging'

  'dragleave .title, dragleave .filesContainer': (event, instance) ->
    $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'

  'drop .title, drop .filesContainer, drop .noteContainer': (event, instance) ->
    event.preventDefault()
    event.stopPropagation()
    for file in event.originalEvent.dataTransfer.files
      name = file.name
      Template.note.encodeImageFileAsURL (res) ->
        upload.call {
          noteId: instance.data._id
          data: res
          name: name
        }, (err, res) ->
          console.log err, res
          $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'
      , file

Template.note.toggleChildren = (instance) ->
  if Meteor.userId()
    Meteor.call 'notes.setShowChildren', {
      noteId: instance.data._id
      show: !instance.data.showChildren
      shareKey: FlowRouter.getParam 'shareKey'
    }
  else
    Session.set 'expand_'+instance.data._id, !Session.get('expand_'+instance.data._id)

Template.note.stripTags = (inputText) ->
  if !inputText
    return
  inputText = inputText.replace(/<\/?span[^>]*>/g, '')
  inputText = inputText.replace(/&nbsp;/g, ' ')
  inputText = inputText.replace(/<\/?a[^>]*>/g, '')
  if inputText
    inputText = inputText.trim()
  inputText
