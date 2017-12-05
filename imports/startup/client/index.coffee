import './routes.coffee'

Meteor.startup ->
    if !Meteor.user() && !Session.get 'introLoaded'
        FlowRouter.go '/intro'
    $(document).on 'keyup', (event) ->
        if !Session.get 'focused'
            switch event.keyCode
                # Down
                when 40
                    Template.note.focus $('.note-item').first()[0]
                # Up
                when 38
                    Template.note.focus $('.note-item').last()[0]