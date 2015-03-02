require 'ffi'

module CoreAudio
    extend FFI::Library
    ffi_lib '/System/Library/Frameworks/CoreAudio.framework/CoreAudio'

    typedef :uint32, :OSStatus

    # @group CoreAudioTypes.h
    class AudioBuffer < FFI::Struct
	layout :mNumberChannels, :uint32,
	       :mDataByteSize, :uint32,
	       :mData, :pointer

	# @return [String]  the raw bytes
	def bytes
	    self[:mData].get_bytes(0, self[:mDataByteSize])
	end

	def bytesize
	    self[:mDataByteSize]
	end

	# @return [Array<Integer>]  an array of samples, converted to signed integers
	def samples_int(bytes_per_channel)
	    self[:mData].get_array_of_int16(0, self[:mDataByteSize]/bytes_per_channel)
	end

	# @return [Array<Float>]    an array of samples, converted to {Float}
	def samples_float(bytes_per_channel)
	    self[:mData].get_array_of_float32(0, self[:mDataByteSize]/bytes_per_channel)
	end
    end

    class AudioBufferList < FFI::Struct
	layout :mNumberBuffers, :uint32,
	       :mBuffers, AudioBuffer

	def self.buffer_list(channels:1, size:nil)
	    self.new.tap do |list|
		list[:mNumberBuffers] = 1
		list[:mBuffers][:mNumberChannels] = channels

		if( size )
		    list[:mBuffers][:mData] = FFI::MemoryPointer.new(size)
		    list[:mBuffers][:mDataByteSize] = size
		else
		    list[:mBuffers][:mDataByteSize] = 0
		end
	    end
	end

	# @return [Array]   the buffers
	def buffers
	    raise("Can't handle multiple buffers yet") if self[:mNumberBuffers] > 1
	    [self[:mBuffers]]
	end

	def bytesize
	    buffers.map(&:bytesize).reduce(&:+)
	end

	# Retrieve the samples as an {Array}, after converting to the requested type
	# @param type		    [Symbol]    :float or :int. Convert the samples to the given type.
	# @param bytes_per_channel  [Number]	the number of bytes for each sample
	# @return [Array<Float,Integer>]	an array of samples, converted to {Float} or {Integer}
	def samples(type, bytes_per_channel)
	    if type == :float
		buffers.map {|buffer| buffer.samples_float(bytes_per_channel)}.flatten
	    else
		buffers.map {|buffer| buffer.samples_int(bytes_per_channel)}.flatten
	    end
	end
    end
    # @endgroup
end

require_relative 'core_audio/audio_device'

module CoreAudio
    # @group AudioHardware.h
    # OSStatus AudioObjectGetPropertyDataSize(AudioObjectID			inObjectID,
    #					      const AudioObjectPropertyAddress* inAddress,
    #					      UInt32                            inQualifierDataSize,
    #					      const void*                       inQualifierData,
    #					      UInt32*                           outDataSize)
    attach_function :AudioObjectGetPropertyDataSize, [AudioObject::ObjectID, AudioObject::PropertyAddress.by_ref, :uint32, :pointer, :pointer], :OSStatus

    # OSStatus AudioObjectGetPropertyData(AudioObjectID                     inObjectID,
    #					  const AudioObjectPropertyAddress* inAddress,
    #					  UInt32                            inQualifierDataSize,
    #					  const void*                       inQualifierData,
    #					  UInt32*                           ioDataSize,
    #					  void*                             outData)
    attach_function :AudioObjectGetPropertyData, [AudioObject::ObjectID, AudioObject::PropertyAddress.by_ref, :uint32, :pointer, :pointer, :pointer], :OSStatus

    # OSStatus AudioObjectSetPropertyData(AudioObjectID                       inObjectID,
    #					  const AudioObjectPropertyAddress*   inAddress,
    #					  UInt32                              inQualifierDataSize,
    #					  const void*                         inQualifierData,
    #					  UInt32                              inDataSize,
    #					  const void*                         inData)
    attach_function :AudioObjectSetPropertyData, [AudioObject::ObjectID, AudioObject::PropertyAddress.by_ref, :uint32, :pointer, :uint32, :pointer], :OSStatus
    # @endgroup

    # @return [Array<AudioObject>]  the list of available audio devices
    def self.devices
	address = AudioObject::PropertyAddress.global_master(AudioHardware::PropertyDevices)
	buffer = AudioObject.system.get_property(address)
	device_IDs = buffer.get_array_of_int32(0, buffer.size/4)
	device_IDs.map {|id| AudioDevice.new(id)}
    end
end
