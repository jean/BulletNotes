{ Meteor } = require 'meteor/meteor'
{ Mongo } = require 'meteor/mongo'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Tracker } = require 'meteor/tracker'
{ $ } = require 'meteor/jquery'
{ FlowRouter } = require 'meteor/kadira:flow-router'
import SimpleSchema from 'simpl-schema'
{ TAPi18n } = require 'meteor/tap:i18n'
sanitizeHtml = require('sanitize-html')

{ Notes } = require '/imports/api/notes/notes.coffee'
{ Files } = require '/imports/api/files/files.coffee'

require './bulletNotes.jade'

import '/imports/ui/components/breadcrumbs/breadcrumbs.coffee'
import '/imports/ui/components/footer/footer.coffee'
import '/imports/ui/components/bulletNoteItem/bulletNoteItem.coffee'

import {
  updateTitle,
  makePublic,
  makePrivate,
  remove,
  insert,
  makeChild
} from '/imports/api/notes/methods.coffee'

import {
  upload
} from '/imports/api/files/methods.coffee'

{ displayError } = '../../lib/errors.js'

# URLs starting with http://, https://, or ftp://
Template.bulletNotes.urlPattern1 =
  /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim

# URLs starting with "www." (without // before it
# or it'd re-link the ones done above).
Template.bulletNotes.urlPattern2 =
  /(^|[^\/])(www\.[\S]+(\b|$))/gim

Template.bulletNotes.onCreated ->
  if @data.showChildren && @data.children && !FlowRouter.getParam 'searchParam'
    Meteor.call 'notes.setChildrenLastShown', {
      noteId: @data._id
    }

  @state = new ReactiveDict()
  @state.setDefault
    showComplete: false

  if @data.note()
    @noteId = @data.note()._id
  else
    @noteId = null

  @favoriteNote = =>
    Meteor.call 'notes.favorite',
      noteId: @data.note()._id

  @deleteNote = =>
    note = @data.note()
    title = sanitizeHtml note.title,
      allowedTags: []
    message = "#{TAPi18n.__('notes.remove.confirm')} “"+title+"”?"
    if confirm(message)
      remove.call { noteId: note._id }, displayError

      FlowRouter.go 'App.home'
      return yes
    return no

Template.bulletNotes.onRendered ->
  $('.title-wrapper').show()
  Template.App_body.recordEvent 'notesRendered', owner: @userId

Template.bulletNotes.helpers
  notes: ->
    NProgress.done()
    parentId = null
    if @note()
      parentId = @note()._id

    if FlowRouter.getParam 'searchTerm'
      Notes.search FlowRouter.getParam 'searchTerm'
    else if parentId
      if (Template.instance().state.get('showComplete') || Session.get('alwaysShowComplete'))
        Notes.find { parent: parentId }, sort: { complete: 1, rank: 1 }
      else
         Notes.find { parent: parentId, complete: false }, sort: { rank: 1 }
    else
      if (Template.instance().state.get('showComplete') || Session.get('alwaysShowComplete'))
        Notes.find { parent: null }, sort: { complete: 1, rank: 1 }
      else
         Notes.find { parent: null, complete: false }, sort: { rank: 1 }

  notesReady: ->
    Template.instance().subscriptionsReady()

  focusedNote: ->
    Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        _id: yes
        body: yes
        title: yes
        favorite: yes
        children: yes

  focusedNoteFiles: () ->
    Meteor.subscribe 'files.note', FlowRouter.getParam 'noteId'
    Files.find { noteId: FlowRouter.getParam 'noteId' }

  focusedNoteBody: ->
    note = Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        _id: yes
        title: yes
    emojione.shortnameToUnicode note.body

  showComplete: () ->
    Template.instance().state.get('showComplete') || Session.get('alwaysShowComplete')

  alwaysShowComplete: () ->
    Session.get 'alwaysShowComplete'

  completedCount: () ->
    if @note()
      Notes.find({ parent: @note()._id, complete: true }).count()
    else
      Notes.find({ parent: null, complete: true }).count()

Template.bulletNotes.events
  'click .toggleComplete': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    instance.state.set('showComplete',!instance.state.get('showComplete'))

  'click .toggleAlwaysShowComplete': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    Session.set('alwaysShowComplete',!Session.get('alwaysShowComplete'))

  'keydown input[type=text]': (event) ->
    # ESC
    if event.which == 27
      event.preventDefault()
      $(event.target).blur()

  'mousedown .js-cancel, click .js-cancel': (event, instance) ->
    event.preventDefault()
    instance.state.set 'editing', false

  'click .uploadHeaderBtn': (event, instance) ->
    input = $(document.createElement('input'))
    input.attr("type", "file")
    input.trigger('click')
    input.change (submitEvent) ->
      console.log "Upload file"
      # console.log submitEvent.originalEvent.dataTransfer.files[0]
      console.log instance
      console.log submitEvent
      file = submitEvent.currentTarget.files[0]
      name = file.name
      Template.bulletNoteItem.encodeImageFileAsURL (res) ->
        upload.call {
          noteId: instance.data.note()._id
          data: res
          name: name
        }, (err, res) ->
          console.log err, res
          $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'
      , file

  'click .newNote': (event, instance) ->
    note = Notes.findOne Template.currentData().note()
    if note
      children = Notes.find { parent: note._id }
      parent = note._id
    else
      children = Notes.find { parent: null }
      parent = null
    if children
      # Overkill, but, meh. It'll get sorted. Literally.
      rank = (children.count() * 40)
    else
      rank = 1
    Meteor.call 'notes.insert', {
      title: ''
      rank: rank
      parent: parent
      shareKey: FlowRouter.getParam('shareKey')
    }, (err, res) ->
      if err
         Template.App_body.showSnackbar
           message: err.message

  'change .note-edit': (event, instance) ->
    target = event.target
    console.log event, instance
    if $(target).val() == 'edit'
      instance.editNote()
    else if $(target).val() == 'delete'
      instance.deleteNote()
    else if $(target).val() == 'favorite'
      instance.favoriteNote()
    else if $(target).val() == 'calendar'
      FlowRouter.go('/calendar/'+instance.data.note()._id)
    else if $(target).val() == 'kanban'
      FlowRouter.go('/kanban/'+instance.data.note()._id)
    target.selectedIndex = 0

  'blur .title-wrapper': (event, instance) ->
    event.stopPropagation()
    title = Template.bulletNoteItem.stripTags(event.target.innerHTML)
    console.log "Got title 191", title
    if title != @title
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data.note()._id
        title: title
        # FlowRouter.getParam 'shareKey',
      }, (err, res) ->
        $(event.target).html Template.bulletNotes.formatText title

Template.bulletNotes.formatText = (inputText, createLinks = true) ->
  if !inputText
    return
  if createLinks
    element = 'a'
  else
    element = 'span'

  replacedText = undefined
  replacePattern1 = undefined
  replacePattern2 = undefined
  replacePattern3 = undefined

  replacedText = inputText.replace(/&nbsp;/gim, ' ')
  replacedText = replacedText.replace Template.bulletNotes.urlPattern1,
    '<'+element+' href="$1" target="_blank" class="previewLink">$1</'+element+'>'
  replacedText = replacedText.replace Template.bulletNotes.urlPattern2,
    '<'+element+' href="http://$2" target="_blank" class="previewLink">$2</'+element+'>'

  # Change email addresses to mailto:: links.
  replacePattern3 = /(([a-zA-Z0-9\-\_\.])+@[a-zA-Z\_]+?(\.[a-zA-Z]{2,6})+)/gim
  replacedText = replacedText.replace replacePattern3,
    '<'+element+' href="mailto:$1">$1</'+element+'>'

  # Highlight Search Terms
  # searchTerm = new RegExp(FlowRouter.getParam('searchTerm'),"gi")
  # replacedText = replacedText.replace searchTerm,
  #   '<span class=\'searchResult\'>$&</span>'

  replacedText = replacedText.replace Notes.hashtagPattern,
    ' <'+element+' href="/search/%23$4" class="tagLink tag-$4">#$4</'+element+'>'

  replacedText = replacedText.replace Notes.namePattern,
    ' <'+element+' href="/search/%40$4" class="atLink at-$4">@$4</'+element+'>'

  replacedText = emojione.shortnameToUnicode replacedText

  return replacedText

Template.bulletNotes.rendered = ->
  notes = this
  NProgress.done()
  $('.mdl-layout__tab-bar').animate({
    scrollLeft: $('.mdl-layout__tab-bar-container').innerWidth()+500
  })

  # $('#notes').selectable
  #   delay: 150
  $('.sortable').nestedSortable
    handle: '.handle'
    items: 'li.note-item'
    placeholder: 'placeholder'
    opacity: .6
    toleranceElement: '> div.noteContainer'

    stop: (event, ui) ->
      Session.set 'dragging', false
      $('.sortable').removeClass 'sorting'

    sort: (event, ui) ->
      Session.set 'dragging', true
      $('.sortable').addClass 'sorting'

    revert: (event, ui) ->
      Session.set 'dragging', false
      $('.sortable').removeClass 'sorting'

    update: (event, ui) ->
      parent = $(ui.item).closest('ol').closest('li').data('id')
      if !parent
        parent = FlowRouter.getParam 'noteId'
      upperSibling = $(ui.item).closest('li').prev('li').data('id')
      Session.set 'dragging', false
      $('.sortable').removeClass 'sorting'

      if upperSibling
        makeChild.call
          noteId: $(ui.item).closest('li').data('id')
          shareKey: FlowRouter.getParam('shareKey')
          upperSibling: upperSibling
          parent: parent
      else
        makeChild.call
          noteId: $(ui.item).closest('li').data('id')
          shareKey: FlowRouter.getParam('shareKey')
          rank: 0
          parent: parent

Template.bulletNotes.getProgressClass = (note) ->
  if (note.progress < 25)
    return 'danger'
  else if (note.progress > 74)
    return 'success'
  else
    return 'warning'
