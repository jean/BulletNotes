// Fill the DB with example data on startup

import { Meteor } from 'meteor/meteor';
import { Notes } from '../../api/notes/notes.js';

Meteor.startup(() => {
  // if the Notes collection is empty
  if (Notes.find().count() === 0) {
    const data = [
      {
        title: 'Do the Tutorial',
        rank: 1,
        createdAt: new Date(),
      },
      {
        title: 'Follow the Guide',
        rank: 2,
        createdAt: new Date(),
      },
      {
        title: 'Read the Docs',
        rank: 3,
        createdAt: new Date(),
      },
      {
        title: 'Discussions',
        rank: 4,
        createdAt: new Date(),
      },
    ];

    data.forEach(note => Notes.insert(note));
  }
});
