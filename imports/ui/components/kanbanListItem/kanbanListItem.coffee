require './kanbanListItem.jade'

require '/imports/ui/components/noteMenu/noteMenu.coffee'
require '/imports/ui/components/noteTitle/noteTitle.coffee'
require '/imports/ui/components/noteBody/noteBody.coffee'

Template.kanbanListItem.helpers
	className: ->
    className = ""
    if @children > 0
      className = className + ' hasChildren'