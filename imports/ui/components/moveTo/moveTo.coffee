{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'

require './moveTo.jade'

Template.moveTo.helpers 
    settings: ->
        {
            position: 'bottom'
            limit: 5
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
        }
        Template.App_body.showSnackbar
            message: "Note moved to "+selected.title+" successfully."
            actionHandler: ->
                FlowRouter.go('/note/'+selected._id)
            actionText: 'View'