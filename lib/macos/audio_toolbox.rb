require 'ffi'

require_relative '../core_foundation'
require_relative '../core_audio/audio_stream'

require_relative 'audio_toolbox/audio_converter'

module AudioToolbox
    extend FFI::Library
    ffi_lib '/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox'

    OSStatus = CoreFoundation::OSStatus
    AudioStreamBasicDescription = CoreAudio::AudioStreamBasicDescription

    typedef :pointer, :AudioConverterRef

    # OSStatus (*AudioConverterComplexInputDataProc)(AudioConverterRef               inAudioConverter,
    #						     UInt32*                         ioNumberDataPackets,
    #						     AudioBufferList*                ioData,
    #						     AudioStreamPacketDescription**  outDataPacketDescription,
    #						     void*                           inUserData)
    callback :AudioConverterComplexInputDataProc, [:AudioConverterRef, :pointer, :pointer, :pointer, :pointer], OSStatus

    # OSStatus AudioConverterNew(const AudioStreamBasicDescription*  inSourceFormat,
    #				 const AudioStreamBasicDescription*  inDestinationFormat,
    #				 AudioConverterRef*                  outAudioConverter)
    attach_function :AudioConverterNew, [AudioStreamBasicDescription.by_ref, AudioStreamBasicDescription.by_ref, :pointer], OSStatus

    # OSStatus AudioConverterFillComplexBuffer(AudioConverterRef                   inAudioConverter,
    #					       AudioConverterComplexInputDataProc  inInputDataProc,
    #					       void*                               inInputDataProcUserData,
    #					       UInt32*                             ioOutputDataPacketSize,
    #					       AudioBufferList*                    outOutputData,
    #					       AudioStreamPacketDescription*       outPacketDescription)
    attach_function :AudioConverterFillComplexBuffer, [:AudioConverterRef, :AudioConverterComplexInputDataProc, :pointer, :pointer, :pointer, :pointer], OSStatus

    # OSStatus AudioConverterSetProperty(AudioConverterRef           inAudioConverter,
    #					 AudioConverterPropertyID    inPropertyID,
    #					 UInt32                      inPropertyDataSize,
    #					 const void*                 inPropertyData)
    attach_function :AudioConverterSetProperty, [:AudioConverterRef, :uint32, :uint32, :pointer], OSStatus

    # Create a new {AudioConverter} that convertes between the given stream formats
    # @param from   [AudioStreamBasicDescription]   the stream format to convert from
    # @param to	    [AudioStreamBasicDescription]   the stream format to convert to
    # @return [AudioConverterRef]
    def self.converter(from, to)
	reference = FFI::MemoryPointer.new(AudioConverterRef)
	status = AudioToolbox.AudioConverterNew(from, to, reference)
	raise "No converter '#{[status].pack('L').reverse}'" unless status.zero?
	AudioConverterRef.new(reference.get_pointer(0)).tap do |converter|
	    converter.from = from
	    converter.to = to
	end
    end
end
