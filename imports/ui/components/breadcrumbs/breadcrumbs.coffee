{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './breadcrumbs.jade'

Template.breadcrumbs.helpers
  parents: ->
    parents = []
    note = Template.instance().data.note()
    if note
      parent = Notes.findOne note.parent,
        fields:
          _id: yes
          parent: yes
          title: yes
      while parent
        parents.unshift parent
        parent = Notes.findOne parent.parent,
          fields:
            _id: yes
            parent: yes
            title: yes
    parents

  focusedTitle: ->
    note = Notes.findOne FlowRouter.getParam 'noteId'
    if note
      emojione.shortnameToUnicode note.title

  focusedId: ->
    note = Notes.findOne FlowRouter.getParam 'noteId'
    if note
      note._id

  title: ->
    emojione.shortnameToUnicode @title

  shareKey: ->
    FlowRouter.getParam 'shareKey'

Template.breadcrumbs.events
  "click a": (event, template) ->
    if ($(event.currentTarget).hasClass('is-active'))
      return false

    if $(event.currentTarget).hasClass('home') && window.location.pathname == '/'
      return false

    event.preventDefault()
    $('input.search').val('')

    offset = $(event.currentTarget).offset()
    $(".mdl-layout__content").animate({ scrollTop: 0 }, 500)
    headerOffset = $('.title-wrapper').offset()
    $('.title-wrapper').fadeOut()

    $('body').append($(event.currentTarget).clone().addClass('zoomingTitle'))
    $('.zoomingTitle').offset(offset).animate({
      left: headerOffset.left
      top: headerOffset.top
      color: 'white'
      fontSize: '20px'
    }, ->
      $('.zoomingTitle').remove()
      FlowRouter.go event.currentTarget.pathname
    )
