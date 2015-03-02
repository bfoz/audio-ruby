module CoreAudio
    class AudioStreamBasicDescription < FFI::Struct
	# @group CoreAudioTypes.h
	FormatFlagIsFloat	    = (1 << 0)
	FormatFlagIsSignedInteger   = (1 << 2)
	# @endgroup

	layout	:mSampleRate, :double,
		:mFormatID, :uint32,
		:mFormatFlags, :uint32,
		:mBytesPerPacket, :uint32,
		:mFramesPerPacket, :uint32,
		:mBytesPerFrame, :uint32,
		:mChannelsPerFrame, :uint32,
		:mBitsPerChannel, :uint32,
		:mReserved, :uint32

	# @!attribute channels
	#   @return [Integer]  the number of channels per frame
	def channels
	    self[:mChannelsPerFrame]
	end

	# @param number	[Integer]   the number of channels per frame
	def channels=(number)
	    self[:mChannelsPerFrame] = number.to_i
	end

	# @!attribute channel_width
	#   @return [Integer]  the number of bits per channel
	def channel_width=(bits)
	    self[:mBitsPerChannel] = bits
	    self[:mBytesPerFrame] = self[:mChannelsPerFrame] * bits / 8
	    self[:mBytesPerPacket] = self[:mBytesPerFrame] * self[:mFramesPerPacket]
	end

	# @!attribute float?
	#   @return [Bool]  true if the stream samples are {Float}
	def float?
	    (self[:mFormatFlags] & FormatFlagIsFloat) != 0
	end

	def integer
	    self[:mFormatFlags] &= ~FormatFlagIsFloat
	    self[:mFormatFlags] |= FormatFlagIsSignedInteger
	end

	# @!attribute sample_rate
	#   @return [Float]  the number of sample frames per second
	def sample_rate;    self[:mSampleRate];	end
	def sample_rate=(rate)
	    self[:mSampleRate] = rate
	end
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
