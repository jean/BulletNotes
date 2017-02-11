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

  Meteor.subscribe 'notes.view',
    FlowRouter.getParam 'noteId',
    FlowRouter.getParam 'shareKey'
  Meteor.subscribe 'notes.children',
    FlowRouter.getParam 'noteId',
    FlowRouter.getParam 'shareKey'

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

Template.notes.helpers
  notes: ->
    parentId = null
    if @note()
      parentId = @note()._id
    if Session.get 'searchTerm'
      Session.set 'level', 0
      Notes.search Session.get 'searchTerm'
    else if parentId
      Session.set 'level', @note().level
      Notes.find { parent: parentId }, sort: rank: 1
    else
      Session.set 'level', 0
      Notes.find { parent: null }, sort: rank: 1
  focusedNote: ->
    Notes.findOne Template.currentData().note()
  notesReady: ->
    Template.instance().subscriptionsReady()
  favorited: ->
    if Template.currentData().note().favorite
      'favorited'
  progress: ->
    setTimeout ->
      $('[data-toggle="tooltip"]').tooltip()
    , 100
    note = Notes.findOne(Template.currentData().note())
    if note
      note.progress
  progressClass: ->
    note = Notes.findOne(Template.currentData().note())
    Template.notes.getProgressClass note
  childNoteCount: ->
    if Template.currentData().note()
      Notes.find({parent:Template.currentData().note()._id}).count()
    else
      Notes.find({parent:null}).count()

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
  'click .favorite': (event, instance) ->
    instance.favoriteNote()
  'change .note-edit': (event, instance) ->
    target = event.target
    if $(target).val() == 'edit'
      instance.editNote()
    else if $(target).val() == 'delete'
      instance.deleteNote()
    else if $(target).val() == 'favorite'
      instance.favoriteNote()
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
  # searchTerm = new RegExp(FlowRouter.getParam('searchTerm'),"gi")
  # replacedText = replacedText.replace searchTerm,
  #   '<span class=\'searchResult\'>$&</span>'

  hashtagPattern = /(([#])([a-z\d-]+))/gim
  replacedText = replacedText.replace hashtagPattern,
    ' <a href="/search/%23$3" class="tagLink tag-$3">#$3</a>'

  namePattern = /(([@])([a-z\d-]+))/gim
  replacedText = replacedText.replace namePattern,
    ' <a href="/search/%40$3" class="atLink at-$3">@$3</a>'

  return replacedText

Template.notes.rendered = ->
  NProgress.done()
  $('.sortable').nestedSortable
    handle: '.handle'
    items: 'li.note-item'
    placeholder: 'placeholder'
    opacity: .6
    toleranceElement: '> div.noteContainer'
    stop: (event, ui) ->
      console.log event, ui
      parent = $(event.toElement).closest('ol').closest('li').data('id')
      upperSibling = $(event.toElement).closest('li').prev('li').data('id')
      console.log parent, upperSibling
      console.log $(event.toElement).closest('li')
      makeChild.call
        noteId: $(event.toElement).closest('li').data('id')
        shareKey: FlowRouter.getParam('shareKey')
        upperSibling: upperSibling
        parent: parent
    # relocate: ->
    #   updateRanks.call
    #     notes: $('.sortable').nestedSortable('toArray')
    #     focusedNoteId: FlowRouter.getParam('noteId')
    #     shareKey: FlowRouter.getParam('shareKey')

Template.notes.getProgressClass = (note) ->
  if (note.progress < 25)
    return 'danger'
  else if (note.progress > 74)
    return 'success'
  else
    return 'warning'
