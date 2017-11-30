pjson = require('/package.json')

import { Random } from 'meteor/random'
import { Accounts } from 'meteor/accounts-base'
import SimpleSchema from 'simpl-schema'

import { Notes } from '/imports/api/notes/notes.coffee'

import childCountDenormalizer from '/imports/api/notes/childCountDenormalizer.coffee'

if Meteor.isServer
  Meteor.startup ->
    TelegramBot.token = Meteor.settings.telegramKey
    TelegramBot.maxTitleLength = 100
    TelegramBot.maxMobileTitleLength = 80
    TelegramBot.maxNoteReturn = 25
    TelegramBot.defaultLimit = 9
    TelegramBot.start()

    TelegramBot.formatNote = (note, mobileFormat) ->
      if note.title
        title = note.title.replace(/(<([^>]+)>|:|_)/ig, " ")
        if mobileFormat
          if title.length > TelegramBot.maxTitleLength
            title = title.substr(0,TelegramBot.maxMobileTitleLength) + '...'
          title
        else
          if title.length > TelegramBot.maxTitleLength
            title = title.substr(0,TelegramBot.maxTitleLength) + '...'
          title + ' - ' + Meteor.settings.public.url + '/note/' + note._id
      else
        '_( Empty Note )_'

    TelegramBot.formatNotes = (notes, limitMultiplier, mobileFormat) ->
      if notes.count()
        ii = 1
        noteIds = []
        notes = notes.fetch()

        showNextPage = false

        if notes.length > TelegramBot.defaultLimit * limitMultiplier
          # There are more notes to scroll to, show the next page option
          showNextPage = true
          notes.pop()

        notes = notes.slice(TelegramBot.defaultLimit * -1)
        msg = ''
        if limitMultiplier > 1
          msg = msg + '`-1` - _( Previous Notes )_\n'
        if showNextPage
          msg = msg + '`0` - _( More Notes )_\n'

        msg = msg + '\n'

        for note in notes
          childCount = note.children || 0
          msg = msg + '`' + ii + '` - ' + '_[' + childCount + ']_ - ' + TelegramBot.formatNote(note, mobileFormat) + '\n'
          ii++

      else
        msg = '_( No Notes )_\n'

      msg

    TelegramBot.generateNoteIds = (notes, limitMultiplier) ->
      noteIds = []
      notes = notes.fetch()
      if notes.length > TelegramBot.defaultLimit * limitMultiplier
        notes.pop()
      notes = notes.slice(TelegramBot.defaultLimit * -1)
      for note in notes
        noteIds.push note._id
      noteIds

    TelegramBot.getNoteRange = (conversation) ->
      (TelegramBot.defaultLimit * (conversation.limitMultiplier-1) + 1)+'-'+(TelegramBot.defaultLimit * (conversation.limitMultiplier))

    TelegramBot.getUser = (data) ->
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      if !user
        msg = 'Hello, I am BulletNotesBot! 😄 \n\nI can help you manage your notes for free.\n\n' +
        'To get started just type `/register`.\n\n'+
        'Or to link your existing BulletNotes account, click here: ' + 
        Meteor.settings.public.url + '/telegramAuth/' + data.chat.id

        TelegramBot.send msg, data.chat.id, true

        false
      else
        Meteor.users.update user._id, $inc:
          telegramBotUseCount:1

        user

    # Listeners

    TelegramBot.setCatchAllText true, (_, message) ->
      user = TelegramBot.getUser message
      if !user
        return false

      msg = 'Note Saved! ' + TelegramBot.formatNote({_id:noteId,title:message.text})
      noteId = Meteor.call 'notes.inbox',
        userId: user._id
        title: message.text
        telegram: true

      if !user.notesCreated
        msg = msg + '\n\nGreat! Your first note! By default notes go into your Inbox, which is itself a note. ' +
        'BulletNotes is all about notes nested within notes, and you can move them anywhere later. Try the `/recent` command to see your notes so far, then add another note.'

      if user.notesCreated == 1
        msg = msg + '\n\nNice, you\'ve got a few notes now. Try out the `/browse` command to view your notes. You will see your Inbox as a note with `1` next to it. ' +
        'Type 1 and hit enter to \'zoom\' into that note and view the notes underneath it. Then you can follow the directions I provide like typing `n` to create a new note, or `e` to edit one.'
      TelegramBot.send msg, message.chat.id, true
      

    TelegramBot.addListener '/start', (command, username, data) ->
      user = TelegramBot.getUser data
      if user
        'Your account is linked. Simply send me any note like `Walk the dog` to get started. Type `/help` for more commands.\n'+
        'The `/browse` and `/recent` commands are worth exploring.'

    TelegramBot.addListener '/help', (command) ->
      msg = 'Hi, I\'m *BulletNotesBot*!\n'
      msg = msg + 'I have the following commands available:\n\n'
      TelegramBot.triggers.text.forEach (post) ->
        msg = msg + '- ' + post.command + '\n'
      msg = msg + '\nVersion: ' + pjson.version + '\n'
      msg = msg + 'Build Date: ' + pjson.releaseDate + '\n\n'
      msg = msg + 'https://bulletnotes.io\n\nSupport: `http://bulletnotes.helpy.io/admin/topics`\nTweet at us: `https://twitter.com/BulletNotes_io`'
      msg

    TelegramBot.addListener '/register', (command, username, data) ->
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      if !user
        Meteor.users.insert
          telegramId: data.chat.id.toString()
          telegramSignUp: true
          createdAt: new Date()

        'You are good to go! Just send me any note you want to rememeber or get done, like `Fix flat tire`.\n\n'+
        'The `/help` command is always there for you if you need it.\n\n'+
        'Welcome to BulletNotes.io! 👍 😎\n\n'+
        '(To link your email later so you can login to the website run `/email`.)'

    TelegramBot.addListener '/email', (command, username, data) ->
      user = TelegramBot.getUser data
      if !user
        false

      email = command[1]

      emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

      # ` 'Fix' for dumb Sublimetext syntax highlihting

      if emailRegex.test email
        Accounts.addEmail user._id, email

        'Alright, you can now request a password for the website here: ' + Meteor.settings.public.url + '/forgot-password'
      else
        'Please provide a valid email.'

    TelegramBot.addListener '/stats', (command, username, data) ->
      user = TelegramBot.getUser data
      if !user
        return false
      
      today = new Date
      date_to_reply = new Date(user.createdAt)
      millis = date_to_reply.getTime() - today.getTime()
      days = Math.ceil(millis / (1000 * 60 * 60 * 24)) * -1
      noteCount = user.notesCreated || 0
      notesDay = (Math.round(noteCount / days * 100) * .01 || 0)

      if user.telegramBotMobileFormat
        mobileStatus = 'You are viewing `mobile` formatted results. (`/mobile` to toggle)'
      else
        mobileStatus = 'You are viewing `detailed` results. (`/mobile` to toggle)'

      mobileStatus + '\n' +
      'Your account was created `' + moment(user.createdAt).fromNow() + '. 📆`\n'+
      'Since then you have created `' + noteCount + '` notes. 😎\n'+
      'That is `' + notesDay + '` notes a day! 👍\n'+
      'We have talked `' + user.telegramBotUseCount + '` times so far. ❤️\n'+
      'Keep up the great work, and thanks for using BulletNotes! 😄'

    TelegramBot.addListener '/mobile', (command, username, data) ->
      user = TelegramBot.getUser data
      if !user
        false

      if !user.telegramBotMobileFormat
        Meteor.users.update user._id, $set:
          telegramBotMobileFormat:true
        'Now showing shorter (mobile-friendly) results. Type `/mobile` again to toggle back.'
      else
        Meteor.users.update user._id, $set:
          telegramBotMobileFormat:false
        'Now showing more detailed results. Type `/mobile` again to toggle back.'



    TelegramBot.addListener '/find', (command, _, data) ->
      user = TelegramBot.getUser data
      if !user
        return false

      # If a limit is not provided as the first param, use 10
      if command.length < 2
        'You must provide a search term. Example: `/find #work`'
      else
        # Drop the /find from the command
        command.shift()
        searchTerm = command.join(' ')
        notes = Notes.search searchTerm, user._id, 10

        msg = 'Here are your search results:\n\n'
        ii = 1
        notes.forEach (note) ->
          title = TelegramBot.formatNote note

          # Highlight search terms
          regex = new RegExp searchTerm, 'gi'
          title = title.replace regex, '`$&`'

          msg = msg + '*' + ii + '* - ' + title + '\n'
          ii++
        msg

    TelegramBot.addListener '/recent', (command, _, data) ->
      user = TelegramBot.getUser data
      if !user
        return false

      # If a limit is not provided as the first param, use the default
      limit = command[1] || TelegramBot.defaultLimit
      limit = Math.min TelegramBot.maxNoteReturn, limit
      notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:limit})

      msg = 'Here are your most recent '+limit+' notes:\n\n'
      ii = 1
      notes.forEach (note) ->
        msg = msg + '*' + ii + '* - ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat) + '\n'
        ii++
      msg

    TelegramBot.addListener '/random', (command, _, data) ->
      user = TelegramBot.getUser data
      if !user
        return false

      # If a limit is not provided as the first param, use the default
      limit = command[1] || TelegramBot.defaultLimit
      limit = Math.min TelegramBot.maxNoteReturn, limit
      notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{_id:Random.choice([1,-1])},limit:limit})

      msg = 'Here are '+limit+' "random" notes:\n\n'
      ii = 1
      notes.forEach (note) ->
        msg = msg + '*' + ii + '* - ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat) + '\n'
        ii++
      msg

    TelegramBot.addListener '/delete', (command, username, data) ->
      user = TelegramBot.getUser data
      if !user
        return false

      if command.length < 2
        # We don't have a search param, grab the most recent notes
        notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:TelegramBot.defaultLimit})

        msg = 'Here are your most recent '+TelegramBot.defaultLimit+' notes:\n\n'
      else
        # We do have a search, find recent notes matching the search
        command.shift()
        searchTerm = command.join(' ')
        notes = Notes.search searchTerm, user._id, TelegramBot.defaultLimit
        msg = 'Here are your most recent '+TelegramBot.defaultLimit+' notes containing `' + searchTerm + '`:\n\n'

      ii = 1
      noteIds = []
      notes.forEach (note) ->
        msg = msg + '*' + ii + '* - ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat) + '\n'
        ii++
        noteIds.push note._id
      msg = msg + '\nReply with the number of the note you want to delete, or reply with `(N)o` to cancel.'

      if searchTerm
        regex = new RegExp searchTerm, 'gi'
        msg = msg.replace regex, '*$&*'

      # Start the conversation
      TelegramBot.startConversation username, data.chat.id, ((username, message, chat_id) ->
        conversation = _.find(TelegramBot.conversations[chat_id], (conversation) ->
          conversation.username == username
        )
        if !conversation.deleteId
          command = message.split ' '
          # If we have a '# y', delete it right away
          if command.length == 2 && command[1].toLowerCase() == "y"
            note = Notes.findOne conversation.noteIds[command[0]-1]
            Notes.update note._id, $set:
                deleted: new Date()

            if note
              childCountDenormalizer.afterInsertNote note.parent

            TelegramBot.send 'Note deleted successfully.', chat_id
            TelegramBot.endConversation username, chat_id
          # Otherwise get confirmation
          else
            if noteSelected = parseInt message, 10
              note = Notes.findOne conversation.noteIds[noteSelected-1]
              conversation.deleteId = note._id
              msg = 'Selected note: ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat) + ' - *Really delete it?* `(Y)es`/`(N)o`'
              TelegramBot.send msg, chat_id, true
            else
              TelegramBot.send 'Delete note cancelled.', chat_id
              TelegramBot.endConversation username, chat_id
        else
          if message.toLowerCase() == 'y' || message.toLowerCase() == 'yes'
            Notes.update conversation.deleteId, $set:
              deleted: new Date()
            TelegramBot.send 'Note deleted successfully.', chat_id
          else
            TelegramBot.send 'Delete note cancelled.', chat_id
          TelegramBot.endConversation username, chat_id
      ),
        noteIds: noteIds

      # The return in this listener will be the first prompt
      msg

    TelegramBot.addListener '/edit', (command, username, data) ->
      user = TelegramBot.getUser data
      if !user
        return false

      if command.length < 2
        # We don't have a search param, grab the most recent notes
        notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:TelegramBot.defaultLimit+1})

        msg = 'Here are your most recent '+TelegramBot.defaultLimit+' notes:\n\n'
      else
        # We do have a search, find recent notes matching the search
        command.shift()
        searchTerm = command.join(' ')
        notes = Notes.search searchTerm, user._id, TelegramBot.defaultLimit+1
        msg = 'Here are your most recent '+TelegramBot.defaultLimit+' notes containing `' + searchTerm + '`:\n\n'

      noteIds = TelegramBot.generateNoteIds notes, 1
      msg = msg + TelegramBot.formatNotes notes, 1
      
      msg = msg + '\nReply with the number of the note you want to edit, or reply with `(N)o` to cancel.'

      if searchTerm
        regex = new RegExp searchTerm, 'gi'
        msg = msg.replace regex, '`$&`'

      # Start the conversation
      TelegramBot.startConversation username, data.chat.id, ((username, message, chat_id) ->
        conversation = _.find(TelegramBot.conversations[chat_id], (conversation) ->
          conversation.username == username
        )
        if !conversation.editId

          # We haven't picked what to edit yet
          noteSelected = parseInt message, 10
          if noteSelected > 0
            command = message.split ' '

            # We have an edit included, apply that right away
            if command.length > 1
              command.shift()
              title = command.join ' '
              Notes.update conversation.noteIds[noteSelected-1], $set:
                title: title
              note = Notes.findOne conversation.noteIds[noteSelected-1]
              TelegramBot.send 'Note edited successfully! ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat), chat_id
              TelegramBot.endConversation username, chat_id

            # No included edit, return the full note text to be edited
            else
              note = Notes.findOne conversation.noteIds[noteSelected-1]
              conversation.editId = note._id
              msg = 'Current note text: ' + note.title + '\n\nReply with the updated text you would like.'
              TelegramBot.send msg, chat_id, true
          else if message == "0" || message == "-1"
            # They have opted to view the next page
            msg = ''
            if message == "0"
              if conversation.limitMultiplier < 10
                conversation.limitMultiplier = conversation.limitMultiplier + 1
              else
                msg = 'Sorry that is all the notes I can show you. Try searching with `/find stuff` or browsing with `/browse`.\n\n'
            # Load the previous page
            else
              if conversation.limitMultiplier > 0
                conversation.limitMultiplier = conversation.limitMultiplier - 1
              else
                msg = 'Already at the first note.\n\n'

            if searchTerm
              msg = msg + 'Here are '+TelegramBot.getNoteRange(conversation)+' of your most recent notes containing `' + searchTerm + '`:\n\n'
              notes = Notes.search searchTerm, user._id, TelegramBot.defaultLimit * conversation.limitMultiplier + 1
            else
              msg = msg + 'Here are '+TelegramBot.getNoteRange(conversation)+' of your most recent notes:\n\n'
              notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:TelegramBot.defaultLimit * conversation.limitMultiplier + 1})

            conversation.noteIds = TelegramBot.generateNoteIds notes, conversation.limitMultiplier
            msg = msg + TelegramBot.formatNotes notes, conversation.limitMultiplier

            msg = msg + '\nReply with the number of the note you want to edit, or reply with `(N)o` to cancel.'

            if searchTerm
              regex = new RegExp searchTerm, 'gi'
              msg = msg.replace regex, '`$&`'
            TelegramBot.send msg, chat_id, true
          else
            TelegramBot.send 'Edit note cancelled.', chat_id
            TelegramBot.endConversation username, chat_id
        else          
          Notes.update conversation.editId, $set:
            title: message
          note = Notes.findOne conversation.editId
          TelegramBot.send 'Note edited successfully! ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat), chat_id
          TelegramBot.endConversation username, chat_id
      ),
        noteIds: noteIds
        limitMultiplier: 1

      # The return in this listener will be the first prompt
      msg

    TelegramBot.addListener '/browse', (command, username, data) ->
      user = TelegramBot.getUser data
      if !user
        return false

      notes = Notes.find({owner:user._id,deleted:{$exists: false},parent:null},{sort:{rank:1},limit:TelegramBot.defaultLimit + 1})

      msg = 'Reply with the number `#` of the note you want to zoom into, `(N)ew` to create a new note, `(E)dit #` to edit a note, `(D)elete #` to delete a note, or `E(x)it` to exit browse mode.\n\n'

      msg = msg + 'Here are your top level notes: \n\n'

      noteIds = TelegramBot.generateNoteIds notes, 1

      msg = msg + TelegramBot.formatNotes notes, 1, user.telegramBotMobileFormat


      # Start the conversation
      TelegramBot.startConversation username, data.chat.id, ((username, message, chat_id) ->
        conversation = _.find(TelegramBot.conversations[chat_id], (conversation) ->
          conversation.username == username
        )

        conversation.noteIds = TelegramBot.generateNoteIds notes, conversation.limitMultiplier
        msg = ''
        command = message.split ' '

        # Handle note creation
        if conversation.creatingNote
          conversation.creatingNote = false
          noteId = Meteor.call 'notes.insert',
            title: message
            parent: conversation.lastNoteId
            ownerId: user._id
            rank: 0
          TelegramBot.send 'Note Saved! ' + TelegramBot.formatNote({_id:noteId,title:message},user.telegramBotMobileFormat), data.chat.id, true
          createdNote = true

        # Handle note deletion
        if conversation.deleteId
          if message.toLowerCase() == 'y' || message.toLowerCase() == 'yes'
            Notes.update conversation.deleteId, $set:
                deleted: new Date()
            msg = 'Note deleted successfully.\n\n'
          else
            msg = 'Delete note cancelled.\n\n'

          conversation.deleteId = null
          deletedNote = true

        # Handle note editing
        if conversation.editId
          Notes.update conversation.editId, $set:
            title: message
          note = Notes.findOne conversation.editId
          TelegramBot.send 'Note edited successfully! ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat), chat_id

          conversation.editId = null
          editedNote = true

        msg = msg + '\nReply with the number `#` of the note you want to zoom into, `(U)p` to go up a level, `(N)ew` to create a new note, `(E)dit #` to edit a note, `(D)elete #` to delete a note, or `E(x)it` to exit browse mode.\n\n'

        noteSelected = parseInt message, 10
        # Load the parent note based on various conditions
        if noteSelected > 0
          note = Notes.findOne conversation.noteIds[noteSelected-1]
          conversation.currentNoteId = note._id
        else if message == "-1"
          if conversation.limitMultiplier > 0
            conversation.limitMultiplier = conversation.limitMultiplier - 1
          else
            msg = 'Already at the first note.\n\n'
          note = Notes.findOne conversation.lastNoteId
        else if message == "0"
          if conversation.limitMultiplier < 10
            conversation.limitMultiplier = conversation.limitMultiplier + 1
          else
            msg = 'Sorry that is all the notes I can show you.. Try searching with `/find stuff` or browsing with `/browse`.\n\n'
          note = Notes.findOne conversation.lastNoteId
        else if message.toLowerCase() == 'u' || message.toLowerCase() == 'up'
          conversation.limitMultiplier = 1
          lastNote = Notes.findOne conversation.lastNoteId
          if lastNote
            note = Notes.findOne lastNote.parent
          else
            # Just show the same note set again
            note = Notes.findOne conversation.lastNoteId
            msg = 'Already at the top level!\n\n'
        # We have to make sure we didn't try and delete a note here, because if we picked No, n, it would trigger this.
        else if !deletedNote && (command[0].toLowerCase() == 'n' || command[0].toLowerCase() == 'new')
          if command.length < 2
            conversation.creatingNote = true
            TelegramBot.send 'Send your new note!', chat_id
            return false
          else
            command.shift()
            noteId = Meteor.call 'notes.insert',
              title: command.join ' '
              parent: conversation.lastNoteId
              ownerId: user._id
              rank: 0
            TelegramBot.send 'Note Saved! ' + TelegramBot.formatNote({_id:noteId,title:message},user.telegramBotMobileFormat), data.chat.id, true

            # Just show the same note set again
            note = Notes.findOne conversation.lastNoteId
        else if command[0].toLowerCase() == 'd' || command[0].toLowerCase() == 'delete'
          if command.length > 1 && noteSelected = parseInt command[1], 10
            # If we have a third param, and that is 'y', delete without confirmation
            if command.length == 3 && command[2] == "y"
              note = Notes.findOne conversation.noteIds[noteSelected-1]
              Notes.update note._id, $set:
                  deleted: new Date()

              if note
                childCountDenormalizer.afterInsertNote note.parent

              msg = 'Note deleted successfully.\n\n'
              # Just show the same note set again
              note = Notes.findOne conversation.lastNoteId
            # Otherwise get confirmation
            else
              note = Notes.findOne conversation.noteIds[noteSelected-1]
              conversation.deleteId = note._id
              msg = 'Selected note: ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat) + ' - *Really delete it?* `(Y)es`/`(N)o`'
              TelegramBot.send msg, chat_id, true
              return false
          else
            msg = 'You must specify a note number. Example: `d 5`\n\n'
        else if command[0].toLowerCase() == 'e' || command[0].toLowerCase() == 'edit'
          if command.length > 1 && noteSelected = parseInt command[1], 10
            # We have params after the number, save that as the note
            if command.length > 2
              command = command.slice 2
              editId = conversation.noteIds[noteSelected-1]
              title = command.join ' '
              Notes.update editId, $set:
                title: title
              note = Notes.findOne conversation.editId
              TelegramBot.send 'Note edited successfully! ' + TelegramBot.formatNote({_id:editId,title:title},user.telegramBotMobileFormat), chat_id
              # Just show the same note set again
              note = Notes.findOne conversation.lastNoteId
            else
              note = Notes.findOne conversation.noteIds[noteSelected-1]
              conversation.editId = note._id
              msg = 'Current note text: `' + note.title + '`\n\nReply with the updated text you would like.'
              TelegramBot.send msg, chat_id, true
              return false
          else
            msg = 'You must specify a note number. Example: `e 5`\n\n'
        else if createdNote || deletedNote || editedNote
          # Just show the same note set again
          note = Notes.findOne conversation.lastNoteId
        else
          TelegramBot.send 'Exited browse mode.', chat_id
          TelegramBot.endConversation username, chat_id
          return false

        if note
          conversation.lastNoteId = note._id
          msg = msg + 'Here are the child notes of ' + TelegramBot.formatNote(note,user.telegramBotMobileFormat) + ': \n\n'
        else
          conversation.lastNoteId = null
          msg = msg + 'Here are your top level notes: \n\n'

        # We add + 1 to this for pagination purposes. So formatNotes can detect if there are more notes to be shown.
        notes = Notes.find({owner:user._id,deleted:{$exists: false},parent:conversation.lastNoteId},{sort:{rank:1},limit:TelegramBot.defaultLimit * conversation.limitMultiplier + 1})

        msg = msg + TelegramBot.formatNotes notes, conversation.limitMultiplier, user.telegramBotMobileFormat

        conversation.noteIds = noteIds
        TelegramBot.send msg, chat_id, true 
      ),
        noteIds: noteIds
        lastNoteId: null
        limitMultiplier: 1

      # The return in this listener will be the first prompt
      msg

