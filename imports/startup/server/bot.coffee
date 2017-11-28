import { Notes } from '/imports/api/notes/notes.coffee'

if Meteor.isServer
  Meteor.startup ->
    TelegramBot.token = Meteor.settings.telegramKey
    TelegramBot.start()

    TelegramBot.addListener '/note', (command) ->
      # command will contain the entire command in an array where command[0] is the command.
      # In this case '/note'. Each argument will follow.

      if command.length < 2
        'You must set a note for me to save. Something like: /note Walk the dog'

      else
        command.shift()
        noteId = Meteor.call 'notes.inbox',
          userId: "2nuEecMRHthr9xKGP"
          title: command.join ' '

        'Saved note: ' + Meteor.settings.public.url + '/note/' + noteId

    TelegramBot.addListener '/start', (command) ->
      'Welcome to BulletNotesBot! I can help you save Notes quickly to BulletNotes.io. In the future I can help you look up notes and mark them as complete.\n\nType `/note Walk the dog.` or `/help` to get started.'

    TelegramBot.addListener '/help', (command) ->
      msg = 'I have the following commands available:\n'
      TelegramBot.triggers.text.forEach (post) ->
        msg = msg + '- ' + post.command + '\n'
        return
      msg
