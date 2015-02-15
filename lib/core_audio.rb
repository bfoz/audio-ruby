require 'ffi'

require_relative 'core_audio/audio_object'

module CoreAudio
    extend FFI::Library
    ffi_lib '/System/Library/Frameworks/CoreAudio.framework/CoreAudio'

    typedef :uint32, :OSStatus

    # AudioHardware.h
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

    # @return [Array<AudioObject>]  the list of available audio devices
    def self.devices
	address = AudioObject::PropertyAddress.global_master(AudioHardware::PropertyDevices)
	buffer = AudioObject.system.get_property(address)
	device_IDs = buffer.get_array_of_int32(0, buffer.size/4)
	device_IDs.map {|id| AudioObject.new(id)}
    end
end
