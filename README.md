Numbers
-------

A Sinatra app for controlling a scoreboard through text files.  Works great with OBS

## Usage
```ruby app.rb -p [port_number]```

### Example
If you want the app to run on port 9999:
```ruby app.rb -p 9999```

## First time running
When running the app for the first time, the text files aren't created yet.

You should hit http://hostname:port/initialize to initialize these files.

## Rest the scoreboard
Click the "Initialize Data" button on the page to re-initialize the data
