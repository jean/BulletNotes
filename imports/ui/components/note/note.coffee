{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '../../../api/notes/notes.coffee'
require './note.jade'

Template.note.helpers children: ->
  if @showChildren
    return Notes.find({ parent: @_id }, sort: rank: 1)
  return
Template.note.onCreated ->
  @state = new ReactiveDict
  return
Template.note.testImage = (url, callback, timeout) ->
  timeout = timeout or 5000
  timedOut = false
  timer = undefined
  img = new Image
  img.onerror =
  img.onabort = ->
    if !timedOut
      clearTimeout timer
      callback url, 'error'
    return

  img.onload = ->
    if !timedOut
      clearTimeout timer
      callback url, 'success', img
    return

  img.src = url
  timer = setTimeout((->
    timedOut = true
    # reset .src to invalid URL so it stops previous
    # loading, but doesn't trigger new load
    img.src = '//!!!!/test.jpg'
    callback url, 'timeout'
    return
  ), timeout)
  return
Template.note.events
  'click .title a': (event) ->
    if !$(event.target).hasClass('tagLink')
      window.open(event.target.href)
  'mouseenter .title a': (event) ->
    if !$(event.target).hasClass('tagLink') && !this.imagePreview
      this.imagePreview = true
      Template.note.testImage event.target.href, ((url, res, img) ->
        if res
          $(event.target).closest('.title').after($(img).addClass('image-preview'))
        return
      ), 1000
  'mouseleave .note': (event) ->
    $(event.target).find('img').remove()
    this.imagePreview = false
  'click .expand': (event) ->
    event.stopImmediatePropagation()
    event.preventDefault()
    Meteor.call 'notes.showChildren', @_id, !@showChildren
    return
  'blur p.body': (event, instance) ->
    event.stopImmediatePropagation()
    body = Template.note.stripTags(event.target.innerHTML)
    Meteor.call 'notes.updateBody', @_id, body, (err, res) ->
      instance.state.set 'editingBody', false
      return
    return
  'blur div.title': (event, instance) ->
    that = this
    event.stopImmediatePropagation()
    title = Template.note.stripTags(event.target.innerHTML)
    if title != @title
      event.target.innerHTML = ''
      Meteor.call 'notes.updateTitle', @_id, title, (err, res) ->
        that.title = title
        return
    return
  'keydown div.title': (event) ->
    `var position`
    `var note`
    note = this
    event.stopImmediatePropagation()
    switch event.keyCode
      # Enter
      when 13
        event.preventDefault()
        if event.shiftKey
          # Edit the body
          note.body = ' yes '
          console.log note
        else
          # Chop the text in half at the cursor
          # put what's on the left in a note on top
          # put what's to the right in a note below
          console.log window.getSelection().anchorOffset
          console.log event
          #return;
          position = event.target.selectionStart
          text = event.target.innerHTML
          topNote = text.substr(0, position)
          bottomNote = text.substr(position)
          # Create a new note below the current.
          Meteor.call 'notes.updateTitle', note._id, topNote, (err, res) ->
            Meteor.call 'notes.insert', '', note.rank + .5, note.parent, (err, res) ->
              Template.notes.calculateRank()
              setTimeout (->
                $(event.target).closest('.note').next().find('.title').focus()
                return
              ), 50
              return
            return
      # Tab
      when 9
        event.preventDefault()
        parent_id = Blaze.getData($(event.currentTarget).closest('.note').prev().get(0))._id
        #console.log(parent_id); return;
        if event.shiftKey
          Meteor.call 'notes.outdent', @_id
        else
          Meteor.call 'notes.makeChild', @_id, parent_id
        return
      # Backspace
      when 8
        if event.currentTarget.innerText.length == 0
          Meteor.call 'notes.remove', @_id
        if window.getSelection().toString() == ''
          position = event.target.selectionStart
          if position == 0
            # We're at the start of the note, add this to the note above, and remove it.
            console.log event.target.value
            prev = $(event.currentTarget).parentsUntil('#notes').prev()
            console.log prev
            prevNote = Blaze.getData(prev.get(0))
            console.log prevNote
            note = this
            console.log note
            Meteor.call 'notes.updateTitle', prevNote._id, prevNote.title + event.target.value, (err, res) ->
              Meteor.call 'notes.remove', note._id, (err, res) ->
                # Moves the caret to the correct position
                prev.find('.title').trigger 'click'
                return
              return
      # Up
      when 38
        # Command is held
        if event.metaKey
          $(event.currentTarget).closest('.note').find('.expand').trigger 'click'
        else
          $(event.currentTarget).closest('.note').prev().find('div.title').focus()
      # Down
      when 40
        if event.metaKey
          $(event.currentTarget).closest('.note').find('.expand').trigger 'click'
        else
          $(event.currentTarget).closest('.note').next().find('div.title').focus()
      # Escape
      when 27
        $(event.currentTarget).blur()
    return

Template.note.stripTags = (inputText) ->
  if !inputText
    return
  inputText = inputText.replace(/<\/?span[^>]*>/g, '')
  inputText = inputText.replace(/<\/?a[^>]*>/g, '')
  inputText

Template.note.helpers
  'class': ->
    className = 'level-' + @level - Session.get('level')
    tags = @title.match(/#\w+/g)
    if tags
      tags.forEach (tag) ->
        className = className + ' tag-' + tag.substr(1).toLowerCase()
        return
    className
  'style': ->
    margin = 2 * (@level - Session.get('level'))
    'margin-left: ' + margin + 'em'
  'expandClass': ->
    if @children > 0 and @showChildren
      'fa-angle-up'
    else if @children > 0
      'fa-angle-down collapsed'
    else
      ''
  'bulletClass': ->
    if @children > 0
      return 'hasChildren'
    return
  'displayTitle': ->
    Template.notes.formatText @title
  'displayBody': ->
    Template.notes.formatText @body

# ---
# generated by js2coffee 2.2.0