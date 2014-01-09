logger = require '../logger'
_ = require 'underscore'

# Provides operations for all statements on top
# of couchDB.
#
module.exports = class StatementMapper

  # returns all stored statements
  #
  #
  #TODO max param
  getAll: (callback) ->
    @dbController.db.view 'find_by/id', (err, docs) =>
      if err
        logger.error "database access failed: " + err
        callback err, []
      else
        statements = []
        for doc in docs
          statements.push doc.value

        callback undefined, statements

  # returns the statement with the given id
  #
  # @param id
  #   id of the statement to look up
  # @param callback
  #   will be called as soon as the statement is retrieved
  #   first callback param: error object
  #   second callback param: retrieved statement
  #
  find: (id, callback) ->
    logger.info 'find statement: ' + id
    @dbController.db.view 'find_by/id', key: id, (err, docs) =>
      if err
        logger.error "database access failed: " + err
        callback err, []
      else
        switch docs.length
          when 0
            logger.info 'statement does not exist: ' + id
            # there is no statement with the given id
            # TODO callback ERROR, null
            callback undefined
          when 1
            logger.info 'statement found: ' + id
            # all right, one statement found
            callback undefined, docs[0].value
          else
            # should not happen, there are more
            # then one statements with the same id
            # TODO callback ERROR, null
            callback 'Multiple Statements for the same id found.'
  #
  #
  constructor: (@dbController) ->

  # Saves this statement to the database
  #
  save: (statement, callback) ->
    # Tries to store this statement and if there
    # is no id, it generates an id, otherwise
    # ist check the two statements for equality
    if statement?.id
    # if the id is already defined,
    # check if the given id is already in the database
      @find statement.id, (err, foundStatement) =>
        if err
          logger.error 'find returned error: ' + err
          # there is no statement with the given id
          # the given statement will be inserted
          callback err
        else
          if foundStatement
            if @isEqual statement, foundStatement
              # all right statement is already in the database
              callback undefined, statement
            else
              # conflict, there is a statement with the
              # same id but a different content
              # TODO callback ERROR, null
              callback {code: 409, message: 'CONFLICTING STATEMENT ALREADY EXISTS' }
          else
            # statement does not exist yet, save it
            @dbController.db.save statement, (err, res) =>
              callback err, statement
    else
      # No id is given, generate one
      statement.id = @generateUUID()
      @dbController.db.save statement, (err, res) =>
        callback err, statement

  isEqual: (s1, s2) ->
    # TODO agents equality etc.
    _.isEqual(s1, s2)


  # RFC4122 A Universally Unique IDentifier (UUID) URN Namespace
  # Generates a UUID from the current date and a random number.
  generateUUID: ->
    d = (new (Date)()).getTime()
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = (d + Math.random()*16)%16 | 0
      d = Math.floor(d/16)
      d = if c is 'x' then r else (r & 0x3|0x8)
      d.toString(16)




