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
    if !Session.get 'dragging'
      Template.App_body.playSound 'navigate'
      offset = $(instance.firstNode).find('.title').offset()
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
