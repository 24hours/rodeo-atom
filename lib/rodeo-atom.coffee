CliStatusView = require './cli-status-view'

module.exports = RodeoAtom =
  cliStatusView: null

  activate: (state) ->
    atom.packages.onDidActivateInitialPackages =>
      @cliStatusView = new CliStatusView(state.cliStatusViewState)


  deactivate: ->
    @cliStatusView.destroy()

  serialize: ->

  config:
    'windowHeight':
      type: 'integer'
      default: 30
      minimum: 0
      maximum: 80
    'clearCommandInput':
      type: 'boolean'
      default: true
    'logConsole':
      type: 'boolean'
      default: false
    'overrideLs':
      title: 'Override ls'
      type: 'boolean'
      default: true
    'shell':
      type: 'string'
      default: if process.platform is 'win32'
          'cmd.exe'
        else
          process.env.SHELL ? '/bin/bash'
