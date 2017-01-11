import './note.jade';

Template.App_note.helpers({
    noteId: function () {
        return FlowRouter.getParam('noteId');
    }
});
