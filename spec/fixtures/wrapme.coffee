SuperWrapMe = require './superwrapme'

module.exports = class WrapMe extends SuperWrapMe
  @reason = 'I just met you'
  maybe: (target, reason) ->
    if @ is target and (reason is WrapMe.reason) then 'passed' else 'failed'
