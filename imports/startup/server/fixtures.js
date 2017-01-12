// Fill the DB with example data on startup

import { Meteor } from 'meteor/meteor';
import { Notes } from '../../api/notes/notes.js';

Meteor.startup(() => {
  // if the Notes collection is empty
  if (Notes.find().count() === 0) {
    const data = [
      {
        title: 'Welcome to Note.d! #orange',
        rank: 1,
        createdAt: new Date(),
      },
      {
        title: 'Sign in and have fun.',
        rank: 2,
        createdAt: new Date(),
      },
      {
        title: 'User Guide: https://github.com/NickBusey/Noted/wiki #blue',
        body: 'There is plenty to do on Noted. Get started now!',
        rank: 2,
        createdAt: new Date(),
      },
    ];

    data.forEach(note => Notes.insert(note));
  }
});
