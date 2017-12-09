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
        Template.bulletNotes.formatText noteElement.data.title
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

Template.noteTitle.saveTitle = (event, instance) ->
  title = Template.bulletNoteItem.stripTags(event.target.innerHTML)

  if !instance.data.title || title != Template.bulletNoteItem.stripTags emojione.shortnameToUnicode instance.data.title
    $(event.target).html Template.bulletNotes.formatText title
    
    # Don't show the 'dirty' status right away, let it try and save first.
    dirtyTimer = setTimeout ->
      instance.state.set 'dirty', true
    , 1000

    if Meteor.user().storeLocation && navigator.geolocation
      success = (position) ->
        Meteor.call 'notes.updateLocation',
          noteId: instance.data._id
          shareKey: FlowRouter.getParam 'shareKey'
          lat: position.coords.latitude
          lon: position.coords.longitude

      error = (error) ->
        Template.App_body.showSnackbar
          message: "Couldn't get location"+error.code
      navigator.geolocation.getCurrentPosition success, error

    Meteor.call 'notes.updateTitle', {
      noteId: instance.data._id
      title: title
      shareKey: FlowRouter.getParam 'shareKey'
    }, (err, res) ->
      clearTimeout dirtyTimer
      if err
        Template.App_body.showSnackbar
          message: err.error
      else
        instance.state.set 'dirty', false

Template.noteTitle.events
  'click .title': (event, instance) ->
    if instance.view.parentView.templateInstance().state
      instance.view.parentView.templateInstance().state.set 'focused', true

  'focus .title': (event, instance) ->
    Session.set 'focused', true
    Template.bulletNoteItem.addAutoComplete event.currentTarget

  'blur .title': (event, instance) ->
    Template.noteTitle.saveTitle event, instance

  'click .title a': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    if !$(event.target).hasClass('tagLink') && !$(event.target).hasClass('atLink')
      window.open(event.target.href)
    else
      $(".mdl-layout__content").animate({ scrollTop: 0 }, 500)
      FlowRouter.go(event.target.pathname)