# Audio

'Audio' is a cross-platform audio device interface that allows you to read and
write audio streams from the comfort and safety of Ruby.

## Cross-Platform Status

Currently, only support for OS X has been implemented. Support for Windows and
Linux will be added in the future. If you feel like working on either of those,
I'm more than happy to take Pull Requests!

## Usage

### Listing Available Audio Devices

The Audio module provides a method that retrieves a list of all of the audio
devices available on your system.

```ruby
require 'audio'

devices = Audio.devices	    # => An Array of Device objects
```

Each Device object has attributes that wrap the various properties provided by
the host operating system. For example, to get a list of device names...

```ruby
Audio.devices.each do |device|
    puts "Device Name: #{device.device_name}"
end
```

Running that on a MacBook Pro (late 2013), with a single external microphone 
connected, produces...

```
Device Name: Built-in Microphone
Device Name: Built-in Output
Device Name: Blue Snowball
```

### Using the default Audio Devices

If you just want to use a default device, Audio has you covered.

```ruby
Audio.default_input     # => Device Name: Built-in Microphone
Audio.default_output    # => Device Name: Built-in Output
```

### Recording Audio

You can record audio from a particular device by calling its `start` method.
Once started, the device will continue recording until its `stop` method is
called. If you provide a block parameter to `start`, it will be called whenever
the host OS provides a new buffer of audio samples.

```ruby
Audio.default_input.start do |*args|
    # Do something fancy
end

sleep 5	    # Record 5 seconds of audio

device.stop
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'audio'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install audio

License
-------

Copyright 2015 Brandon Fosdick <bfoz@bfoz.net> and released under the BSD license.
