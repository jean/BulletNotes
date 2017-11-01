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

require './notes.jade'

import '/imports/ui/components/breadcrumbs/breadcrumbs.coffee'
import '/imports/ui/components/footer/footer.coffee'
import '/imports/ui/components/note/note.coffee'

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
Template.notes.urlPattern1 =
  /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim

# URLs starting with "www." (without // before it
# or it'd re-link the ones done above).
Template.notes.urlPattern2 =
  /(^|[^\/])(www\.[\S]+(\b|$))/gim

Template.notes.onCreated ->
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

Template.notes.onRendered ->
  $('.title').first().focus()
  Template.note.focus $('.title').first()[0]

  if Session.get 'referral'
    Meteor.call 'users.referral', {
      referral: Session.get 'referral' 
      userId: Meteor.userId()
    }


Template.notes.helpers
  notes: ->
    NProgress.done()
    parentId = null
    if @note()
      parentId = @note()._id

    if FlowRouter.getParam 'searchTerm'
      Notes.search FlowRouter.getParam 'searchTerm'
    else if parentId
      Notes.find { parent: parentId }, sort: rank: 1
    else
      Notes.find { parent: null }, sort: rank: 1

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

Template.notes.events
  'click .js-cancel': (event, instance) ->
    instance.state.set 'editing', false

  'keydown input[type=text]': (event) ->
    # ESC
    if event.which == 27
      event.preventDefault()
      $(event.target).blur()

  'mousedown .js-cancel, click .js-cancel': (event, instance) ->
    event.preventDefault()
    instance.state.set 'editing', false

  'click .favorite': (event, instance) ->
    instance.favoriteNote()

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
      Template.note.encodeImageFileAsURL (res) ->
        upload.call {
          noteId: instance.data.note()._id
          data: res
          name: name
        }, (err, res) ->
          console.log err, res
          $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'
      , file

  'click .newNote': (event, instance) ->
    Template.App_body.playSound 'newNote'
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
    }

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
    title = Template.note.stripTags(event.target.innerHTML)
    console.log "Got title 191", title
    if title != @title
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data.note()._id
        title: title
        # FlowRouter.getParam 'shareKey',
      }, (err, res) ->
        $(event.target).html Template.notes.formatText title

Template.notes.formatText = (inputText, createLinks = true) ->
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
  replacedText = replacedText.replace Template.notes.urlPattern1,
    '<'+element+' href="$1" target="_blank" class="previewLink">$1</'+element+'>'
  replacedText = replacedText.replace Template.notes.urlPattern2,
    '<'+element+' href="http://$2" target="_blank" class="previewLink">$2</'+element+'>'

  # Change email addresses to mailto:: links.
  replacePattern3 = /(([a-zA-Z0-9\-\_\.])+@[a-zA-Z\_]+?(\.[a-zA-Z]{2,6})+)/gim
  replacedText = replacedText.replace replacePattern3,
    '<'+element+' href="mailto:$1">$1</'+element+'>'

  # Highlight Search Terms
  # searchTerm = new RegExp(FlowRouter.getParam('searchTerm'),"gi")
  # replacedText = replacedText.replace searchTerm,
  #   '<span class=\'searchResult\'>$&</span>'

  hashtagPattern = /((\s#)([a-z\d-]+))/gim
  replacedText = replacedText.replace hashtagPattern,
    ' <'+element+' href="/search/%23$3" class="tagLink tag-$3">#$3</'+element+'>'

  namePattern = /((\s@)([a-z\d-]+))/gim
  replacedText = replacedText.replace namePattern,
    ' <'+element+' href="/search/%40$3" class="atLink at-$3">@$3</'+element+'>'

  replacedText = emojione.shortnameToUnicode replacedText

  return replacedText

Template.notes.rendered = ->
  notes = this
  NProgress.done()
  # $('#notes').selectable
  #   delay: 150
  $('.sortable').nestedSortable
    handle: 'div.dot'
    items: 'li.note-item'
    placeholder: 'placeholder'
    opacity: .6
    toleranceElement: '> div.noteContainer'

    # revert: 100
    # distance: 5
    sort: (event, ui) ->
      Session.set 'dragging', true
      $('.sortable').addClass 'sorting'

    revert: (event, ui) ->
      console.log "reverting"
      Session.set 'dragging', false
      $('.sortable').removeClass 'sorting'

    update: (event, ui) ->
      Template.App_body.playSound 'sort'
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

Template.notes.getProgressClass = (note) ->
  if (note.progress < 25)
    return 'danger'
  else if (note.progress > 74)
    return 'success'
  else
    return 'warning'
