// Definition of the links collection

import { Mongo } from 'meteor/mongo';

export const Notes = new Mongo.Collection('notes');

// if ( Meteor.isServer ) {
//   Notes._ensureIndex( { title: 1, body: 1 } );
// }