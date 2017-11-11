{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '/imports/api/notes/notes.coffee'

require './menu.jade'

Template.menu.onCreated ->
  @state = new ReactiveDict
  @state.setDefault
    menuOpen: true
  setInterval ->
    percentFull = Counter.get('userNotes') / Template.App_body.getTotalNotesAllowed() * 100
    if document.querySelector('#spaceUsedBar')
      document.querySelector('#spaceUsedBar').MaterialProgress.setProgress(percentFull);

    if Meteor.user()
      # THis is hacky. Should be somewhere else.
      if Meteor.user().language
        T9n.setLanguage(Meteor.user().language)
        TAPi18n.setLanguage(Meteor.user().language)

      if Session.get 'referral'
        Meteor.call 'users.referral', {
          referral: Session.get 'referral' 
        }
        Session.set 'referral', null


  , 1000

Template.menu.helpers
  displayName: ->
    displayName = ''
    if Meteor.user().emails
      email = Meteor.user().emails[0].address
      displayName = email.substring(0, email.indexOf('@'))
    else
      displayName = Meteor.user().profile.name
    displayName

  totalNotesAllowed: ->
    Template.App_body.getTotalNotesAllowed()

  referralCount: ->
    Meteor.user().referralCount

  notes: ->
    Notes.find { favorite: true }, sort: favoritedAt: -1

  activeNoteClass: (note) ->
    active = ActiveRoute.name('Notes.show') and FlowRouter.getParam('_id') == note._id
    active and 'active'

  hideUndoButton: ->
    if tx.Transactions.find(
      user_id: Meteor.userId()
      $or: [
        { undone: null }
        { undone: $exists: false }
      ]
      expired: $exists: false).count() then true

  hideRedoButton: ->
    undoneRedoConditions = ->
      'var undoneRedoConditions'
      undoneRedoConditions =
        $exists: true
        $ne: null
      lastAction = tx.Transactions.findOne({
        user_id: Meteor.userId()
        $or: [
          { undone: null }
          { undone: $exists: false }
        ]
        expired: $exists: false
      }, sort: lastModified: -1)
      if lastAction
        undoneRedoConditions['$gt'] = lastAction.lastModified
      undoneRedoConditions

    if tx.Transactions.find(
      user_id: Meteor.userId()
      undone: undoneRedoConditions()
      expired: $exists: false).count() then true

  action: (type) ->
    sel =
      user_id: Meteor.userId()
      expired: $exists: false
    # This is for autopublish scenarios
    existsOrNot = if type == 'redo' then undone: undoneRedoConditions() else $or: [
      { undone: null }
      { undone: $exists: false }
    ]
    sorter = {}
    sorter[if type == 'redo' then 'undone' else 'lastModified'] = -1
    transaction = tx.Transactions.findOne(_.extend(sel, existsOrNot), sort: sorter)
    transaction and transaction.description

  ready: ->
    Session.get 'ready'

  menuPin: ->
    if Meteor.user()
      Meteor.user().menuPin
    else
      true

  menuPinIcon: ->
    if Meteor.user().menuPin
      'chevron_left'
    else
      'chevron_right'

  muteIcon: ->
    if Meteor.user().muted
      'volume_off'
    else
      'volume_up'

  muteClass: ->
    if !Meteor.user().muted
      'mdl-button--colored'

Template.menu.events
  'click .js-menu': (event, instance) ->
    Session.set 'menuOpen', !Session.get('menuOpen')

  'click .js-logout': ->
    Meteor.logout()
    FlowRouter.go '/'

  'click #menuPin': ->
    if Meteor.user().menuPin
      Meteor.call('users.setMenuPin', {menuPin:false})
      Template.App_body.playSound 'menuClose'
    else
      Meteor.call('users.setMenuPin', {menuPin:true})
      Template.App_body.playSound 'menuOpen'

  'click #mute': ->
    Template.App_body.toggleMute()

  'click .homeLink': ->
    $('#searchForm input').val('')

  'click #undo': (event) ->
    tx.undo()

  'click #redo': (event) ->
    tx.redo()

Template.registerHelper 'increment', (count) ->
  return count + 1

Template.registerHelper 'emoji', (argument) ->
  emojione.shortnameToUnicode argument
