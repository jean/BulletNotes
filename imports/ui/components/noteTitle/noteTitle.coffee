require './noteTitle.jade'

Template.noteTitle.onCreated ->
  @state = new ReactiveDict()
  @state.setDefault
      focused: false

Template.noteTitle.onRendered ->
  noteElement = this

  Tracker.autorun ->

    if noteElement.data.title
      $(noteElement.firstNode).find('.title').first().html(
        Template.notes.formatText noteElement.data.title
      )
      $(noteElement.firstNode).find('> .noteContainer .encryptedTitle').first().html(
        Template.notes.formatText noteElement.data.title
      )

Template.noteTitle.helpers
  editable: ->
    if !Meteor.userId()
      return false
    else
      return true

Template.noteTitle.events
  'click .title': (event, instance) ->
    event.stopImmediatePropagation()
    if instance.state
      instance.state.set 'focused', true
      Session.set 'focused', true

  'blur .title': (event, instance) ->
    Template.instance().state.set 'focused', false
    Session.set 'focused', false
    that = this
    event.stopPropagation()
    # If we blurred because we hit tab and are causing an indent
    # don't save the title here, it was already saved with the
    # indent event.
    if Session.get 'indenting'
      Session.set 'indenting', false
      return

    title = Template.note.stripTags(event.target.innerHTML)

    if !@title || title != Template.note.stripTags emojione.shortnameToUnicode @title
      setTimeout ->
        $(event.target).html Template.notes.formatText title
      , 20
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data._id
        title: title
        shareKey: FlowRouter.getParam 'shareKey'
      }, (err, res) ->
        if err
          Template.App_body.showSnackbar
            message: err.error
