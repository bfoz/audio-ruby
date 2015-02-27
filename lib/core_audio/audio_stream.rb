module CoreAudio
    class AudioStreamBasicDescription < FFI::Struct
	layout	:mSampleRate, :double,
		:mFormatID, :uint32,
		:mFormatFlags, :uint32,
		:mBytesPerPacket, :uint32,
		:mFramesPerPacket, :uint32,
		:mBytesPerFrame, :uint32,
		:mChannelsPerFrame, :uint32,
		:mBitsPerChannel, :uint32,
		:mReserved, :uint32
    end

    class AudioValueRange < FFI::Struct
	layout	:minimum, :double,
		:maximum, :double
    end

    class AudioStreamRangedDescription < FFI::Struct
	layout	:mFormat, AudioStreamBasicDescription,
		:mSampleRateRange, AudioValueRange
    end

    class AudioStream < AudioObject
	PropertyIsActive                    = 'sact',
	PropertyDirection                   = 'sdir',
	PropertyTerminalType                = 'term',
	PropertyStartingChannel             = 'schn',
	PropertyLatency                     = CoreAudio::AudioDevice::PropertyLatency,
	PropertyVirtualFormat               = 'sfmt',
	PropertyAvailableVirtualFormats     = 'sfma',
	PropertyPhysicalFormat              = 'pft ',
	PropertyAvailablePhysicalFormats    = 'pfta'

	def virtual_format
	    address = PropertyAddress.global_master(PropertyVirtualFormat)
	    buffer = get_property(address)
	    AudioStreamBasicDescription.new(buffer)
	end

	def virtual_formats
	    address = PropertyAddress.global_master(PropertyAvailableVirtualFormats)
	    buffer = get_property(address)
	    count = buffer.size/AudioStreamRangedDescription.size
	    output = []
	    count.times do |i|
		output << AudioStreamRangedDescription.new(buffer)
		buffer += AudioStreamRangedDescription.size
	    end
	    output
	end
    end
end
