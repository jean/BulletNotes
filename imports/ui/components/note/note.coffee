{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'
{ Files } = require '/imports/api/files/files.coffee'
{ ReactiveDict } = require 'meteor/reactive-dict'

require './note.jade'
require '/imports/ui/components/file/file.coffee'
require '/imports/ui/components/share/share.coffee'
require '/imports/ui/components/encrypt/encrypt.coffee'
require '/imports/ui/components/moveTo/moveTo.coffee'
require '/imports/ui/components/noteMenu/noteMenu.coffee'
require '/imports/ui/components/noteTitle/noteTitle.coffee'

import {
  favorite,
  setShowContent
} from '/imports/api/notes/methods.coffee'

import {
  upload
} from '/imports/api/files/methods.coffee'

Template.note.previewXOffset = 20
Template.note.previewYOffset = 20

Template.note.encodeImageFileAsURL = (cb,file) ->
  reader = new FileReader

  reader.onloadend = ->
    cb reader.result

  reader.readAsDataURL file

Template.note.isValidImageUrl = (url, callback) ->
  $ '<img>',
    src: url
    error: ->
      callback url, false
    load: ->
      callback url, true

Template.note.onCreated ->
  if @data.showChildren && @data.children && !FlowRouter.getParam 'searchParam'
    Meteor.call 'notes.setChildrenLastShown', {
      noteId: @data._id
    }

  @state = new ReactiveDict()
  @state.setDefault
    focused: false
    showComplete: false
    showMoveTo: false

  query = Notes.find({_id:@data._id})

  handle = query.observeChanges(
    changed: (id, fields) ->
      if fields.title != null
        $('#noteItem_'+id).find('.title').first().html(
          Template.notes.formatText fields.title
        )
  )

Template.note.onRendered ->
  noteElement = this

  Session.set('expand_'+this.data._id, this.data.showChildren)

  Tracker.autorun ->
    if noteElement.data.body
      bodyHtml = Template.notes.formatText noteElement.data.body
      $(noteElement.firstNode).find('.body').first().show().html(
        bodyHtml
      )

    $('.fileItem').draggable
      revert: true

    $('.note-item').droppable
      drop: (event, ui ) ->
        if event.toElement && event.toElement.className.indexOf('fileItem') > -1
          event.stopPropagation()
          Meteor.call 'files.setNote',
            fileId: event.toElement.dataset.id
            noteId: event.target.dataset.id
          , (err, res) ->

Template.note.helpers
  currentShareKey: () ->
    FlowRouter.getParam('shareKey')

  count: () ->
    @rank / 2

  files: () ->
    Meteor.subscribe 'files.note', @_id
    Files.find { noteId: @_id }

  childNotes: () ->
    if (
      (@showChildren && !FlowRouter.getParam('searchParam')) ||
      Session.get('expand_'+@_id)
    )
      Meteor.subscribe 'notes.children',
        @_id,
        FlowRouter.getParam 'shareKey'
      if (Template.instance().state.get('showComplete') || Session.get('alwaysShowComplete'))
        Notes.find { parent: @_id }, sort: { complete: 1, rank: 1 }
      else
        Notes.find { parent: @_id, complete: false }, sort: { rank: 1 }

  showComplete: () ->
    Template.instance().state.get('showComplete') || Session.get('alwaysShowComplete')

  alwaysShowComplete: () ->
    Session.get 'alwaysShowComplete'

  completedCount: () ->
    Notes.find({ parent: @_id, complete: true }).count()

  editingClass: (editing) ->
    editing and 'editing'

  expandClass: () ->
    if Notes.find({parent: @_id}).count() > 0
      if (
        (@showChildren && !FlowRouter.getParam('searchParam')) ||
        Session.get('expand_'+@_id)
      )
        'remove'
      else
        'add'

  hoverInfo: ->
    info = 'Created '+moment(@createdAt).fromNow()+'.'
    if @updatedAt
      info += ' Updated '+moment(@updatedAt).fromNow()+'.'
    if @updateCount
      info += ' Edits: '+@updateCount
    if @childrenShownCount
      info += ' Views: '+@childrenShownCount
    info

  className: ->
    className = "note"
    if @title
      tags = @title.match(/#\w+/g)
      if tags
        tags.forEach (tag) ->
          className = className + ' tag-' + tag.substr(1).toLowerCase()

    if @showChildren || Session.get('expand_'+@_id)
      showChildren = true
    if !showChildren && @children > 0
      className = className + ' hasHiddenChildren'
    if @children > 0
      className = className + ' hasChildren'
    if @shared
      className = className + ' shared'
    if Template.instance().state.get 'focused'
      className = className + ' focused'
    if @encrypted
      className = className + ' encrypted'
    if @favorite
      className = className + ' favorite'
    if @encryptedRoot
      className = className + ' encryptedRoot'
    className

  userOwnsNote: ->
    Meteor.userId() == @owner

  progress: ->
    setTimeout ->
      $('[data-toggle="tooltip"]').tooltip()
    , 100
    @progress

  progressClass: ->
    Template.notes.getProgressClass this

  showEncrypt: ->
    Template.instance().state.get 'showEncrypt'

  showShare: ->
    Template.instance().state.get 'showShare'

  showMoveTo: ->
    Template.instance().state.get 'showMoveTo'

  displayEncrypted: ->
    if @encrypted || @encryptedRoot
      true

  editable: ->
    if !Meteor.userId()
      return false
    else
      return true

  hasContent: ->
    Meteor.subscribe 'files.note', @_id
    (@body || Files.find({ noteId: @_id }).count() > 0)

  canIndent: ->
    if $('#noteItem_'+@_id).prev('.note-item').length
      true

  canUnindent: ->
    $('#noteItem_'+@_id).parentsUntil('.note-item').closest('.note-item').length

Template.note.events
  'click .encryptLink, click .decryptLink, click .encryptedIcon': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    instance.state.set 'showEncrypt', true
    # Hacky ugly shit to work around MDL modal bs
    that = this
    setTimeout ->
      $('#toggleEncrypt_'+that._id).click()
      setTimeout ->
        $('.modal.in').parent().append($('.modal-backdrop'))
        $('input.cryptPass').focus()
      , 250
    , 50

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
      Template.note.encodeImageFileAsURL (res) ->
        upload.call {
          noteId: instance.data._id
          data: res
          name: name
        }, (err, res) ->
          if err
            alert err
          $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'
      , file

  'click .title a': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    if !$(event.target).hasClass('tagLink') && !$(event.target).hasClass('atLink')
      window.open(event.target.href)
    else
      Template.App_body.playSound 'navigate'
      $(".mdl-layout__content").animate({ scrollTop: 0 }, 500)
      FlowRouter.go(event.target.pathname)

  'click .toggleComplete': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    instance.state.set('showComplete',!instance.state.get('showComplete'))

  'click .toggleAlwaysShowComplete': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    Session.set('alwaysShowComplete',!Session.get('alwaysShowComplete'))

  'click .favorite, click .unfavorite': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    Template.App_body.playSound 'favorite'
    favorite.call
      noteId: instance.data._id

  'click .showContent': (event, instance) ->
    event.stopImmediatePropagation()
    setShowContent.call
      noteId: instance.data._id
      showContent: true
    , (err, res) ->
      $(event.target).closest('.noteContainer').find('.body')
        .html(emojione.shortnameToUnicode(instance.data.body))

  'click .hideContent': (event, instance) ->
    event.stopImmediatePropagation()
    setShowContent.call
      noteId: instance.data._id
      showContent: false

  'click .moveTo': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    Template.note.showMoveTo instance

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

  'mouseover .tagLink, mouseover .atLink': (event) ->
    if Session.get 'dragging'
      return
    notes = Notes.search event.target.innerHTML, null, 5
    $('#tagSearchPreview').html('')
    notes.forEach (note) ->
      # Only show the note in the preview box if it is not the current note being hovered.
      if note._id != $(event.target).closest('.note-item').data('id')
        $('#tagSearchPreview').append('<li><a class="previewTagLink">'+
        Template.notes.formatText(note.title,false)+'</a></li>')
          .css('top', event.pageY - Template.note.previewYOffset + 'px')
          .css('left', event.pageX + Template.note.previewXOffset + 'px')
          .show()
    $('#tagSearchPreview').append('<li><a class="previewTagViewAll">Click to view all</a></li>')

  'mousemove .tagLink, mousemove .atLink': (event) ->
    $('#tagSearchPreview').css('top', event.pageY - Template.note.previewYOffset + 'px')
      .css 'left', event.pageX + Template.note.previewXOffset + 'px'

  'mouseleave .tagLink, mouseleave .atLink': (event) ->
    $('#tagSearchPreview').hide()

  'mouseover .previewLink': (event) ->
    if Session.get 'dragging'
      return
    date = new Date
    url = event.currentTarget.href
    Template.note.isValidImageUrl url, (url, valid) ->
      if valid
        if url.indexOf("?") > -1
          imageUrl = url + "&" + date.getTime()
        else
          imageUrl = url + "?" + date.getTime()
        $('body').append '<p id=\'preview\'><a href=\'' +
          url + '\' target=\'_blank\'><img src=\'' + imageUrl +
          '\' alt=\'Image preview\' /></p>'
        $('#preview').css('top', event.pageY - Template.note.previewYOffset + 'px')
          .css('left', event.pageX + Template.note.previewXOffset + 'px')
          .fadeIn 'fast'
        # This needs to be here
        $('#preview img').mouseleave ->
          $('#preview').remove()

  'mousemove .previewLink': (event) ->
    $('#preview').css('top', event.pageY - Template.note.previewYOffset + 'px')
      .css 'left', event.pageX + Template.note.previewXOffset + 'px'

  'mouseleave .previewLink': (event) ->
    $('#preview').remove()

  'paste .title': (event, instance) ->
    event.preventDefault()
    event.stopImmediatePropagation()

    lines = event.originalEvent.clipboardData.getData('text/plain').split(/\n/g)

    # Add the first line to the current note
    line = lines.shift()
    combinedTitle = event.target.innerHTML + line
    Meteor.call 'notes.updateTitle', {
      noteId: instance.data._id
      title: combinedTitle
      shareKey: FlowRouter.getParam('shareKey')
    }

    lines.forEach (line) ->
      if line
        Meteor.call 'notes.insert', {
          title: line
          rank: instance.data.rank + 1
          parent: instance.data.parent
          shareKey: FlowRouter.getParam('shareKey')
        }

  'keydown .title': (event, instance) ->
    note = this
    event.stopImmediatePropagation()
    switch event.keyCode
      # Cmd ] - Zoom in
      when 221
        if event.metaKey
          FlowRouter.go('/note/'+instance.data._id)

      # Cmd [ - Zoom out
      when 219
        if event.metaKey
          FlowRouter.go('/note/'+instance.data.parent)

      # U - Upload
      when 85
        if event.metaKey && event.shiftKey
          $('#noteItem_'+instance.data._id).find('.fileInput').first().trigger('click')

      # Enter
      when 13
        event.preventDefault()
        event.stopImmediatePropagation()

        if $('.textcomplete-dropdown:visible').length < 1
          if event.shiftKey
            # Edit the body
            setShowContent.call
              noteId: instance.data._id
              showContent: true
            , (err, res) ->
              $(event.target).siblings('.body').fadeIn().focus()
          else if event.ctrlKey
            Template.note.toggleChildren instance
          else
            Template.App_body.playSound 'newNote'
            # Create a new note below the current.
            Meteor.call 'notes.insert', {
              title: bottomNote
              rank: note.rank + 1
              parent: note.parent
              shareKey: FlowRouter.getParam('shareKey')
            }
            Template.note.focus $(event.target).closest('.note-item').next()[0]

            return

            # TODO: This code needs cleaned up a bit
            # If the cursor is at the start of the line, it duplicates rather than moves the text.
            # Also it is wonky when links or tags are present

            # Chop the text in half at the cursor
            # put what's on the left in a note on top
            # put what's to the right in a note below
            # position = event.target.selectionStart
            # text = event.target.innerHTML
            # if !position
            #   range = window.getSelection().getRangeAt(0)
            #   position = range.startOffset
            #
            # topNote = text.substr(0, position)
            # bottomNote = text.substr(position)
            # if topNote != Template.note.stripTags(note.title)
            #   Meteor.call 'notes.updateTitle', {
            #     noteId: note._id
            #     title: topNote
            #     shareKey: FlowRouter.getParam('shareKey')
            #   }
            # Template.App_body.playSound 'newNote'
            # # Create a new note below the current.
            # Meteor.call 'notes.insert', {
            #   title: bottomNote
            #   rank: note.rank + 1
            #   parent: note.parent
            #   shareKey: FlowRouter.getParam('shareKey')
            # }, (err, res) ->
            #   if err
            #     Template.App_body.showSnackbar
            #       message: err.error
            #       actionHandler: ->
            #         FlowRouter.go('/account')
            #       ,
            #       actionText: 'More Info'
            # Template.note.focus $(event.target).closest('.note-item').next()[0]

      # D - Duplicate
      when 68
        if event.metaKey || event.ctrlKey
          event.preventDefault()
          Meteor.call 'notes.duplicate', instance.data._id

      # Tab
      when 9
        event.preventDefault()
        Session.set 'indenting', true
        # First save the title in case it was changed.
        title = Template.note.stripTags(event.target.innerHTML)
        if title != @title
          Meteor.call 'notes.updateTitle',
            noteId: @_id
            title: title

            # FlowRouter.getParam 'shareKey'
        parent_id = Blaze.getData(
          $(event.currentTarget).closest('.note-item').prev().get(0)
        )._id
        noteId = @_id
        if event.shiftKey
          Meteor.call 'notes.outdent', {
            noteId: noteId
            shareKey: FlowRouter.getParam 'shareKey'
          }
          Template.note.focus $('#noteItem_'+noteId)[0]

        else
          childCount = Notes.find({parent: parent_id}).count()
          Meteor.call 'notes.makeChild', {
            noteId: @_id
            parent: parent_id
            rank: (childCount*2)+1
            shareKey: FlowRouter.getParam 'shareKey'
          }
          Template.note.focus $('#noteItem_'+noteId)[0]

      # Backspace / delete
      when 8
        if $('.textcomplete-dropdown:visible').length
          # We're showing a dropdown, don't do anything.
          return

        # If the note is empty and hit delete again, or delete with ctrl key
        if event.currentTarget.innerText.trim().length == 0 || event.ctrlKey
          $(event.currentTarget).closest('.note-item').fadeOut()
          Template.App_body.playSound 'delete'
          Meteor.call 'notes.remove',
            noteId: @_id
            shareKey: FlowRouter.getParam 'shareKey'
          Template.note.focus $(event.currentTarget).closest('.note-item').prev()[0]
          return

        # If there is no selection
        if window.getSelection().toString() == ''
          position = event.target.selectionStart
          if !position
            range = window.getSelection().getRangeAt(0)
            position = range.startOffset
          if position == 0
            # We're at the start of the note,
            # add this to the note above, and remove it.
            prev = $(event.currentTarget).closest('.note-item').prev()
            prevNote = Blaze.getData(prev.get(0))
            note = this
            Template.App_body.playSound 'delete'
            Meteor.call 'notes.updateTitle', {
              noteId: prevNote._id
              title: prevNote.title + event.target.innerHTML
              shareKey: FlowRouter.getParam 'shareKey'
            }, (err, res) ->
              if !err
                Meteor.call 'notes.remove',
                  noteId: note._id,
                  shareKey: FlowRouter.getParam 'shareKey',
                  (err, res) ->
                    # Moves the caret to the correct position
                    if !err
                      prev.find('div.title').focus()

      # . Period
      when 190
        if event.metaKey
          Template.note.toggleChildren(instance)

      # Up
      when 38
        if $('.textcomplete-dropdown:visible').length
          # We're showing a dropdown, don't do anything.
          event.preventDefault()
          return false
        if $(event.currentTarget).closest('.note-item').prev().length
          if event.metaKey || event.ctrlKey
            event.stopImmediatePropagation()
            # Move note above the previous note
            item = $(event.currentTarget).closest('.note-item')
            prev = item.prev()
            upperSibling = Blaze.getView(prev.prev()[0]).templateInstance()
            if prev.length == 0
              return
            prev.css('z-index', 999).css('position', 'relative').animate { top: item.height() }, 250
            item.css('z-index', 1000).css('position', 'relative').animate { top: '-' + prev.height() }, 300, ->
              setTimeout ->
                prev.css('z-index', '').css('top', '').css 'position', ''
                item.css('z-index', '').css('top', '').css 'position', ''
                item.insertBefore prev
                setTimeout ->
                  Template.note.focus item[0]
                , 100

                Meteor.call 'notes.makeChild', {
                  noteId: instance.data._id
                  parent: instance.data.parent
                  upperSibling: upperSibling.data._id
                  shareKey: FlowRouter.getParam 'shareKey'
                }
              , 50
          else
            # Focus on the previous note
            Template.note.focus $(event.currentTarget).closest('.note-item').prev()[0]
        else
          # There is no previous note in the current sub list, go up a note.
          Template.note.focus $(event.currentTarget).closest('ol').closest('.note-item')[0]

      # Down
      when 40
        # Command is held
        if event.metaKey || event.ctrlKey
          # Move down
          item = $(event.currentTarget).closest('.note-item')
          next = item.next()
          if next.length == 0
            return
          next.css('z-index', 999).css('position', 'relative').animate { top: '-' + item.height() }, 250
          item.css('z-index', 1000).css('position', 'relative').animate { top: next.height() }, 300, ->
            setTimeout ->
              next.css('z-index', '').css('top', '').css 'position', ''
              item.css('z-index', '').css('top', '').css 'position', ''
              item.insertAfter next

              setTimeout ->
                Template.note.focus item[0]
              , 100

              view = Blaze.getView(next[0])
              upperSibling = view.templateInstance()

              Meteor.call 'notes.makeChild', {
                noteId: instance.data._id
                parent: instance.data.parent
                upperSibling: upperSibling.data._id
                shareKey: FlowRouter.getParam 'shareKey'
              }
            , 50
        else
          if $('.textcomplete-dropdown:visible').length
            # We're showing a dropdown, don't do anything.
            event.preventDefault()
            return false
          # Go to a child note if available
          note = $(event.currentTarget).closest('.note-item')
            .find('ol .note-item').first()
          if !note.length
            # If not, get the next note on the same level
            note = $(event.currentTarget).closest('.note-item').next()
          if !note.length
            # Nothing there, keep going up levels.
            count = 0
            searchNote = $(event.currentTarget).parent().closest('.note-item')
            while note.length < 1 && count < 10
              note = searchNote.next()
              if !note.length
                searchNote = searchNote.parent().closest('.note-item')
                count++
          if note.length
            Template.note.focus note[0]
          else
            $('#new-note').focus()

      # Escape
      when 27
        if $('.textcomplete-dropdown:visible').length
          # We're showing a dropdown, don't do anything.
          event.preventDefault()
          return false
        $(event.currentTarget).blur()
        window.getSelection().removeAllRanges()

      # M - Move To
      when 77
        if event.metaKey && event.shiftKey
          Template.note.showMoveTo instance

  'keydown .body': (event, instance) ->
    note = this
    event.stopImmediatePropagation()
    switch event.keyCode
      # Escape
      when 27
        if $('.textcomplete-dropdown:visible').length
          # We're showing a dropdown, don't do anything.
          event.preventDefault()
          return false
        $(event.currentTarget).blur()
        window.getSelection().removeAllRanges()

  'blur .title': (event, instance) ->
    instance.state.set 'focused', false
    Session.set 'focused', false

  'focus .title, focus .body': (event, instance) ->
    Session.set 'focused', true
    Template.note.addAutoComplete event.currentTarget

  'blur .body': (event, instance) ->
    event.stopPropagation()
    that = this
    Session.set 'focused', false
    # console.log event.target
    body = Template.note.stripTags event.target.innerHTML
    if body != Template.note.stripTags(@body)
      Meteor.call 'notes.updateBody', {
        noteId: instance.data._id
        body: body
        shareKey: FlowRouter.getParam 'shareKey'
      }, (err, res) ->
        that.body = body
        $(event.target).html Template.notes.formatText body
    if !body
      $(event.target).fadeOut()

  'click .expand': (event, instance) ->
    event.stopImmediatePropagation()
    event.preventDefault()
    $('.mdl-tooltip').fadeOut().remove()
    if instance.data.showChildren
      Template.App_body.playSound 'collapse'
    else
      Template.App_body.playSound 'expand'

    Template.note.toggleChildren(instance)

  'click .dot': (event, instance) ->
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

  'dragover .title, dragover .filesContainer': (event, instance) ->
    $(event.currentTarget).closest('.noteContainer').addClass 'dragging'

  'dragleave .title, dragleave .filesContainer': (event, instance) ->
    $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'

  'drop .title, drop .filesContainer, drop .noteContainer': (event, instance) ->
    event.preventDefault()
    event.stopPropagation()

    if event.toElement
      console.log "Move file!"
    else
      for file in event.originalEvent.dataTransfer.files
        name = file.name
        Template.note.encodeImageFileAsURL (res) ->
          upload.call {
            noteId: instance.data._id
            data: res
            name: name
          }, (err, res) ->
            if err
              alert err
            $(event.currentTarget).closest('.noteContainer').removeClass 'dragging'
        , file

Template.note.toggleChildren = (instance) ->
  if Meteor.userId()
    if !instance.data.showChildren
        Meteor.call 'notes.setChildrenLastShown', {
          noteId: instance.data._id
        }

    Meteor.call 'notes.setShowChildren', {
      noteId: instance.data._id
      show: !instance.data.showChildren
      shareKey: FlowRouter.getParam('shareKey')
    }

  if !Session.get('expand_'+instance.data._id)
    $(instance.firstNode).find('.childWrap').first().hide()
    Session.set('expand_'+instance.data._id, true)
    # Hacky fun to let Meteor render the child notes first
    setTimeout ->
      $(instance.firstNode).find('ol').first().hide()
      $(instance.firstNode).find('.childWrap').first().show()
      $(instance.firstNode).find('ol').first().slideDown()
    , 1
  else
    $(instance.firstNode).find('ol').first().slideUp ->
      Session.set('expand_'+instance.data._id, false)

Template.note.focus = (noteItem) ->
  view = Blaze.getView(noteItem)
  instance = view.templateInstance()
  $(noteItem).find('.title').first().focus()
  if instance.state
    instance.state.set 'focused', true
    Session.set 'focused', true

Template.note.stripTags = (inputText) ->
  if !inputText
    return
  inputText = inputText.replace(/<\/?span[^>]*>/g, '')
  inputText = inputText.replace(/&nbsp;/g, ' ')
  inputText = inputText.replace(/<\/?a[^>]*>/g, '')
  if inputText
    inputText = inputText.trim()
  inputText

Template.note.setCursorToEnd = (ele) ->
  range = document.createRange()
  sel = window.getSelection()
  range.setStart ele, 1
  range.collapse true
  sel.removeAllRanges()
  sel.addRange range
  ele.focus()

Template.note.showMoveTo = (instance) ->
    instance.state.set 'showMoveTo', true
    setTimeout ->
      $('#toggleMoveTo_'+instance.data._id).click()
      setTimeout ->
        $('.modal.in').parent().append($('.modal-backdrop'))
        setTimeout ->
          $('input.moveToInput').focus()
        , 500
      , 250
    , 50

Template.note.addAutoComplete = (target) ->
  $(target).textcomplete [ {
    match: /\B:([\-+\w]*)$/
    search: (term, callback) ->
      results = []
      results2 = []
      results3 = []
      $.each Template.App_body.emojiStrategy, (shortname, data) ->
        if shortname.indexOf(term) > -1
          results.push shortname
        else
          if data.aliases != null and data.aliases.indexOf(term) > -1
            results2.push shortname
          else if data.keywords != null and data.keywords.indexOf(term) > -1
            results3.push shortname
        return
      if term.length >= 3
        results.sort (a, b) ->
          a.length > b.length
        results2.sort (a, b) ->
          a.length > b.length
        results3.sort()
      newResults = results.concat(results2).concat(results3)
      callback newResults
      return
    template: (shortname) ->
      '<img class="emojione" src="//cdn.jsdelivr.net/emojione/assets/png/' +
      Template.App_body.emojiStrategy[shortname].unicode + '.png"> :' + shortname + ':'
    replace: (shortname) ->
      Template.App_body.insertingData = true
      return ':' + shortname + ': '
    index: 1
    maxCount: 10
  } ], footer:
    '<a href="http://www.emoji.codes" target="_blank">'+
    'Browse All<span class="arrow">»</span></a>'
