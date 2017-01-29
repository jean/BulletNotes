{ Notes } = require '/imports/api/notes/notes.js'
{ Meteor } = require 'meteor/meteor'
{ Mongo } = require 'meteor/mongo'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Tracker } = require 'meteor/tracker'
{ $ } = require 'meteor/jquery'
{ FlowRouter } = require 'meteor/kadira:flow-router'
{ SimpleSchema } = require 'meteor/aldeed:simple-schema'
{ TAPi18n } = require 'meteor/tap:i18n'

require './notes.html'

#import '/imports/ui/components/footer/footer.coffee'
import '/imports/ui/components/note/note.coffee'

import {
  updateTitle,
  makePublic,
  makePrivate,
  remove,
  insert,
} from '../../../api/notes/methods.js'

{ displayError } = '../../lib/errors.js'

Template.notes.onCreated ->
  console.log @data.note()._id
  @subscribe 'notes.children', @data.note()._id
  @state = new ReactiveDict
  @state.setDefault
    editing: false
    editingNote: false
    notesReady: false

Template.notes.helpers
  notes: ->
    Notes.find { parent: Template.currentData().note()._id }, sort: rank: 1
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
  'blur input[type=text]': (event, instance) ->
    # if we are still editing (we haven't just clicked the cancel button)
    if instance.state.get('editing')
      instance.saveNote()
    return
  'submit .js-edit-form': (event, instance) ->
    event.preventDefault()
    instance.saveNote()
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
    that = this
    event.stopPropagation()
    title = Template.note.stripTags(event.target.innerHTML)
    if title != @title
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data
        newTitle: title
        # FlowRouter.getParam 'shareKey',
      }, (err, res) ->
        that.title = title
        $(event.target).html Template.notes.formatText title
  'click .js-toggle-note-privacy': (event, instance) ->
    instance.toggleNotePrivacy()
    return
  'click .js-delete-note': (event, instance) ->
    instance.deleteNote()
    return
  'click .js-note-add': (event, instance) ->
    instance.$('.js-note-new input').focus()
    return
  'submit .js-note-new': (event) ->
    event.preventDefault()
    $input = $(event.target).find('[type=text]')
    if !$input.val()
      return
    insert.call {
      parent: Template.instance().data
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