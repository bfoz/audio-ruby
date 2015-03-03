require 'ffi'

require_relative 'core_audio/audio_types'

module CoreAudio
    extend FFI::Library
    ffi_lib '/System/Library/Frameworks/CoreAudio.framework/CoreAudio'

    typedef :uint32, :OSStatus
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

    # @return [AudioDevice] the default input device
    def self.default_input
	address = AudioObject::PropertyAddress.global_master(AudioHardware::PropertyDefaultInputDevice)
	buffer = AudioObject.system.get_property(address)
	AudioDevice.new(buffer.get_uint32(0))
    end

    # @return [AudioDevice] the default output device
    def self.default_output
	address = AudioObject::PropertyAddress.global_master(AudioHardware::PropertyDefaultOutputDevice)
	buffer = AudioObject.system.get_property(address)
	AudioDevice.new(buffer.get_uint32(0))
    end
end
