{exec} = require "child_process"

task "build", "Compile coffee scripts into plain Javascript files", ->
  exec "coffee -c -o lib src/*.coffee", (err, stdout, stderr) ->
    if err?
      console.error "Error :"
      console.dir   err
      console.log stdout
      return console.error stderr

    console.log "Done!"
