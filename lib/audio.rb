require_relative 'core_audio'
require_relative 'macos/audio_toolbox'

module Audio
    # @return [Array<Device>]  the list of available audio devices
    def self.devices
	CoreAudio.devices
    end
end
