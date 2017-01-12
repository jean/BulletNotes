import './view-note.jade';

Template.App_viewNote.onCreated(function () {
  Session.set('searchTerm','');
});

Template.App_viewNote.helpers({
    noteId: function () {
        return FlowRouter.getParam('noteId');
    }
});
