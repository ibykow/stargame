module.exports = class SuperWrapMe
  callme: (target) ->  if @ is target then 'passed' else 'failed'
