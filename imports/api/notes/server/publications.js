// All links-related publications

import { Meteor } from 'meteor/meteor';
import { check } from 'meteor/check'
import { Match } from 'meteor/check'
import { Notes } from '../notes.js';

Meteor.publish('notes.all', function () {
  return Notes.find({ owner: this.userId });
});

Meteor.publish('notes.search', function(search) {
  check(search, Match.Maybe(String));

  let query = {};
  let projection = { limit: 100 };

console.log('search',search);
    let regex = new RegExp( search, 'i' );

    query = {
      
         title: regex 
      
    };

console.log(query,projection);
  return Notes.find( query, projection );
});