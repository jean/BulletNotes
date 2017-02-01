{ Notes } = require '/imports/api/notes/notes.coffee'
{ Meteor } = require 'meteor/meteor'
{ Mongo } = require 'meteor/mongo'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Tracker } = require 'meteor/tracker'
{ $ } = require 'meteor/jquery'
{ FlowRouter } = require 'meteor/kadira:flow-router'
{ SimpleSchema } = require 'meteor/aldeed:simple-schema'
{ TAPi18n } = require 'meteor/tap:i18n'
sanitizeHtml = require('sanitize-html')

require './notes.jade'
require './notes.styl'

import '/imports/ui/components/breadcrumbs/breadcrumbs.coffee'
import '/imports/ui/components/footer/footer.coffee'
import '/imports/ui/components/note/note.coffee'

import {
  updateTitle,
  makePublic,
  makePrivate,
  remove,
  insert,
  updateRanks
} from '/imports/api/notes/methods.coffee'

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
  @state = new ReactiveDict
  @state.setDefault
    editing: false
    editingNote: false
    notesReady: false

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

Template.notes.helpers
  # notes: () ->
  #   Notes.find { parent: parentId }, sort: rank: 1
  notes: ->
    parentId = null
    if @note()
      parentId = @note()._id

    if Template.currentData().searchTerm
      Meteor.subscribe 'notes.search', Template.currentData().searchTerm
    else
      Meteor.subscribe 'notes.view',
        parentId
        # FlowRouter.getParam 'shareKey'
      Meteor.subscribe 'notes.children',
        parentId
        # FlowRouter.getParam 'shareKey'
    Session.set 'searchTerm', Template.currentData().searchTerm

    if parentId
      Session.set 'level', @note().level
      Notes.find { parent: parentId }, sort: rank: 1
    else if Template.currentData().searchTerm
      Session.set 'level', 0
      Notes.search Template.currentData().searchTerm
    else
      Session.set 'level', 0
      Notes.find { parent: null }, sort: rank: 1
  focusedNote: ->
    Notes.findOne Template.currentData().note()
  notesReady: ->
    # Template.instance().state.get 'notesReady'
    Template.instance().subscriptionsReady()

Template.notes.events
  'click .js-cancel': (event, instance) ->
    instance.state.set 'editing', false
    return
  'keydown input[type=text]': (event) ->
    # ESC
    if event.which == 27
      event.preventDefault()
      $(event.target).blur()
    return
  'mousedown .js-cancel, click .js-cancel': (event, instance) ->
    event.preventDefault()
    instance.state.set 'editing', false
    return
  'change .note-edit': (event, instance) ->
    target = event.target
    if $(target).val() == 'edit'
      instance.editNote()
    else if $(target).val() == 'delete'
      instance.deleteNote()
    else
      instance.toggleNotePrivacy()
    target.selectedIndex = 0
    return
  'blur .title-wrapper': (event, instance) ->
    event.stopPropagation()
    title = Template.note.stripTags(event.target.innerHTML)
    if title != @title
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data.note()._id
        title: title
        # FlowRouter.getParam 'shareKey',
      }, (err, res) ->
        $(event.target).html Template.notes.formatText title
  'click .js-toggle-note-privacy': (event, instance) ->
    instance.toggleNotePrivacy()
    return
  'click .js-delete-note': (event, instance) ->
    instance.deleteNote()
  'click .js-note-add': (event, instance) ->
    instance.$('.js-note-new input').focus()
    return
  'submit .js-note-new': (event) ->
    event.preventDefault()
    $input = $(event.target).find('[type=text]')
    if !$input.val()
      return
    insert.call {
      parent: Template.instance().noteId
      title: $input.val()
    }, displayError
    $input.val ''
    return

Template.notes.formatText = (inputText) ->
  if !inputText
    return
  replacedText = undefined
  replacePattern1 = undefined
  replacePattern2 = undefined
  replacePattern3 = undefined

  replacedText = inputText.replace(/&nbsp;/gim, ' ')
  replacedText = replacedText.replace Template.notes.urlPattern1,
    '<a href="$1" target="_blank" class="previewLink">$1</a>'
  replacedText = replacedText.replace Template.notes.urlPattern2,
    '<a href="http://$2" target="_blank" class="previewLink">$2</a>'

  # Change email addresses to mailto:: links.
  replacePattern3 = /(([a-zA-Z0-9\-\_\.])+@[a-zA-Z\_]+?(\.[a-zA-Z]{2,6})+)/gim
  replacedText = replacedText.replace replacePattern3,
    '<a href="mailto:$1">$1</a>'

  # Highlight Search Terms
  searchTerm = Session.get('searchTerm')
  replacedText = replacedText.replace searchTerm,
    '<span class=\'searchResult\'>$&</span>'

  hashtagPattern = /(([#])([a-z\d-]+))/gim
  replacedText = replacedText.replace hashtagPattern,
    ' <a href="/search/%23$3" class="tagLink tag-$3">#$3</a>'

  namePattern = /(([@])([a-z\d-]+))/gim
  replacedText = replacedText.replace namePattern,
    ' <a href="/search/%40$3" class="atLink at-$3">@$3</a>'

  return replacedText

Template.notes.rendered = ->
  $('.sortable').nestedSortable
    handle: '.handle'
    items: 'li.note-item'
    placeholder: 'placeholder'
    forcePlaceholderSize: true
    opacity: .6
    toleranceElement: '> div.noteContainer'
    relocate: ->
      updateRanks.call 
        notes: $('.sortable').nestedSortable('toArray')
        focusedNoteId: FlowRouter.getParam('_id'),
        shareKey: FlowRouter.getParam('shareKey')
