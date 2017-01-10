import './note.html';

import '../../components/notes/notes.js';
import { Notes } from '/imports/api/notes/notes.js';

Template.App_note.helpers({
    noteId: function () {
        return FlowRouter.getParam('noteId');
    }
});
