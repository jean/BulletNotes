require './noteTitle.jade'
require './noteTitle.styl'

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

Template.noteTitle.helpers
  className: ->
    className = ''
    if Template.instance().state.get 'dirty'
      className += ' dirty'
    className

  editable: ->
    if !Meteor.userId()
      return false
    else
      return true

Template.noteTitle.events
  'click .title': (event, instance) ->
    console.log instance
    if instance.state
      instance.view.parentView.templateInstance().state.set 'focused', true
      Session.set 'focused', true

  'blur .title': (event, instance) ->
    # If we blurred because we hit tab and are causing an indent
    # don't save the title here, it was already saved with the
    # indent event.
    if Session.get 'indenting'
      Session.set 'indenting', false
      return

    title = Template.note.stripTags(event.target.innerHTML)

    if !@title || title != Template.note.stripTags emojione.shortnameToUnicode @title
      instance.state.set 'dirty', true
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
        else
          instance.state.set 'dirty', false
