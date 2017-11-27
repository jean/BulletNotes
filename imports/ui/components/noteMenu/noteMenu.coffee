import './noteMenu.styl'
import './noteMenu.jade'

Template.noteMenu.onCreated ->
  @state = new ReactiveDict()
  @state.setDefault
    showMenu: false

Template.noteMenu.helpers
  showMenu: ->
    Template.instance().state.get 'showMenu'

Template.noteMenu.events
  'click .menuToggle': (event, instance) ->
    event.stopImmediatePropagation()
    if instance.state.get('showMenu') == true
      document.querySelector('#menu_'+instance.data._id).MaterialMenu.hide()
      instance.state.set 'showMenu', false
    else
      instance.state.set 'showMenu', true
      # Give the menu time to render
      instance.menuTimer = setTimeout ->
        document.querySelector('#menu_'+instance.data._id).MaterialMenu.show()
      , 20

  'click .zoom': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    console.log event, instance
    if !Session.get 'dragging'
      console.log "In"
      Template.App_body.playSound 'navigate'
      offset = $(instance.firstNode).parent().find('.title').offset()
      $(".mdl-layout__content").animate({ scrollTop: 0 }, 500)
      headerOffset = $('.title-wrapper').offset()
      $('.title-wrapper').fadeOut()

      $('body').append($(instance.firstNode).find('.title').first().clone().addClass('zoomingTitle'))
      $('.zoomingTitle').offset(offset).animate({
        left: headerOffset.left
        top: headerOffset.top
        color: 'white'
        fontSize: '20px'
      }, ->
        $('.zoomingTitle').remove()
        FlowRouter.go '/note/'+instance.data._id+'/'+(FlowRouter.getParam('shareKey')||'')
      )


  'click .share': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    instance.state.set 'showShare', true

    that = this
    setTimeout ->
      $('#toggleShare_'+that._id).click()
      setTimeout ->
        $('.modal.in').parent().append($('.modal-backdrop'))
      , 250
    , 50

  'click .indent': (event, instance) ->
    Meteor.call 'notes.makeChild', {
      noteId: instance.data._id
      parent: $('#noteItem_'+instance.data._id).prev().data('id')
      shareKey: FlowRouter.getParam 'shareKey'
    }

  'click .unindent': (event, instance) ->
    Meteor.call 'notes.makeChild', {
      noteId: instance.data._id
      parent: $('#noteItem_'+instance.data._id).parentsUntil('.note-item').closest('.note-item').parentsUntil('.note-item').closest('.note-item').data('id')
      shareKey: FlowRouter.getParam 'shareKey'
    }

  'click .upload': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    $('#noteItem_'+instance.data._id).find('.fileInput').first().trigger('click')

  'change .fileInput': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    console.log event
    console.log instance
    for file in event.currentTarget.files
      name = file.name
      Template.bulletNoteItem.encodeImageFileAsURL (res) ->
        upload.call {
          noteId: instance.data._id
          data: res
          name: name
        }, (err, res) ->
          if err
            alert err
          $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'
      , file

  'click .favorite, click .unfavorite': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    Template.App_body.playSound 'favorite'
    favorite.call
      noteId: instance.data._id

  'click .moveTo': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    Template.bulletNoteItem.showMoveTo instance

  'click .duplicate': (event) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    Meteor.call 'notes.duplicate', @_id

  'click .addBody': (event, instance) ->
    setShowContent.call
      noteId: instance.data._id
      showContent: true
    , (err, res) ->
      setTimeout (->
        $(event.target).closest('.noteContainer').find('.body').fadeIn().focus()
      ), 20

  'click a.delete': (event) ->
    event.preventDefault()
    Template.App_body.playSound 'delete'
    $(event.currentTarget).closest('.note').remove()
    Meteor.call 'notes.remove',
      noteId: @_id
      shareKey: FlowRouter.getParam 'shareKey'
    , (err, res) ->
      if err
        window.location = window.location
