require_relative 'core_audio'

module Audio
    # @return [Array<Device>]  the list of available audio devices
    def self.devices
	CoreAudio.devices
    end
end
