{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'

require './moveTo.jade'

Template.moveTo.helpers 
    settings: ->
        {
            position: 'bottom'
            limit: 10
            rules: [
                {
                    collection: Notes
                    field: 'title'
                    template: Template.notePill
                    matchAll: true
                }
            ]
        }

Template.moveTo.events
    'autocompleteselect input': (event, instance, selected) ->
        Meteor.call 'notes.makeChild', {
            noteId: instance.data._id
            parent: selected._id
            shareKey: FlowRouter.getParam 'shareKey'
            expandParent: false
            rank: 0
        }
        Template.App_body.showSnackbar
            message: "Note moved to "+selected.title+" successfully."
            actionHandler: ->
                FlowRouter.go('/note/'+selected._id)
                $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)
            actionText: 'View'
            timeout: 5000

Template.notePill.maxTitleLength = 35

Template.notePill.helpers
    shortTitle: ->
        title = @title
        if title.length > Template.notePill.maxTitleLength
            title = title.substr(0,Template.notePill.maxTitleLength) + '...'
        title

    parentTitle: ->
        parentTitle = ''
        if @parent
            parentTitle = Notes.findOne(@parent).title
            if parentTitle.length > Template.notePill.maxTitleLength
                parentTitle = parentTitle.substr(0,Template.notePill.maxTitleLength) + '...'
        else
            parentTitle = 'Home'
        parentTitle