CliStatusView = require './cli-status-view'
{CompositeDisposable} = require 'atom'
{spawn, exec} = require 'child_process'
Promise = require 'promise'

module.exports = RodeoAtom =
  cliStatusView: null
  state : null
  enviroment : new Promise (fulfill, reject) ->
    cmd = 'test -e /etc/profile && source /etc/profile;test -e ~/.profile && source ~/.profile; node -pe "JSON.stringify(process.env)"'
    exec cmd, (code, stdout, stderr) ->
      try
        process.env = JSON.parse(stdout)
        fulfill(process.env)
      catch e
        reject(e)

  activate: (state) ->
    @state = state
    if atom.config.get 'rodeo-atom.enableOnStart'
      atom.packages.onDidActivateInitialPackages =>
        @cliStatusView = new CliStatusView(state.cliStatusViewState)

    atom.commands.add 'atom-workspace', 'rodeo-atom:enable': => @enable()

    if atom.config.get 'rodeo-atom.launchRodeoOnStart'
      verify = @verifyRodeo()
      console.log(verify)
      verify.then ()->
        exec 'echo "rodeo ." > $TMPDIR/rodeo.command ; chmod u+x $TMPDIR/rodeo.command ; open $TMPDIR/rodeo.command', env:process.env, (e,s,s2) ->
        # error handling is ignore, because error should not happen here
      ,(msg) ->
        atom.notifications.addWarning(msg)

  deactivate: ->
    @cliStatusView.destroy()

  enable: ->
    @cliStatusView = new CliStatusView(@state.cliStatusViewState)

  verifyRodeo: ->
    parent = @
    ret = new Promise (fulfill, reject) ->
      parent.enviroment.then (env) ->
        child = exec 'which rodeo', env: env, (error, stdout, stderr) ->
          if error == null
            child = exec 'ps aux | grep -v grep | grep rodeo', env: env, (error, stdout, stderr) ->
              if error != null
                fulfill()
              else
                reject('Rodeo already running')
          else
            console.log('exec error: ' + error)
            reject('Rodeo does not seems to be installed')

      console.log("step N")
      return ret

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
    'shell':
      type: 'string'
      default: if process.platform is 'win32'
          'cmd.exe'
        else
          process.env.SHELL ? '/bin/bash'
    'enableOnStart':
      type: 'boolean'
      default: 'true'
    'launchRodeoOnStart':
      type: 'boolean'
      default: 'false'
    'rodeoPort':
      type: 'integer'
      default: 5000
