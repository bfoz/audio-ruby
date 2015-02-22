require_relative 'audio_object'

module CoreAudio
    AudioDeviceIOProcID = FFI::Pointer
    typedef :pointer, :AudioDeviceIOProcID

    # @group AudioHardware.h

    # typedef OSStatus (*AudioDeviceIOProc)(AudioObjectID           inDevice,
    #					    const AudioTimeStamp*   inNow,
    #					    const AudioBufferList*  inInputData,
    #					    const AudioTimeStamp*   inInputTime,
    #					    AudioBufferList*        outOutputData,
    #					    const AudioTimeStamp*   inOutputTime,
    #					    void*                   inClientData);
    callback :AudioDeviceIOProc, [AudioObject::ObjectID, :pointer, AudioBufferList.by_ref, :pointer, AudioBufferList.by_ref, :pointer, :pointer], :OSStatus

    # OSStatus AudioDeviceCreateIOProcID(AudioObjectID           inDevice,
    #					 AudioDeviceIOProc       inProc,
    #					 void*                   inClientData,
    #					 AudioDeviceIOProcID*    outIOProcID)
    attach_function :AudioDeviceCreateIOProcID, [AudioObject::ObjectID, :AudioDeviceIOProc, :pointer, :pointer], :OSStatus

    # OSStatus AudioDeviceDestroyIOProcID(AudioObjectID           inDevice,
    #					  AudioDeviceIOProcID     inIOProcID
    attach_function :AudioDeviceDestroyIOProcID, [AudioObject::ObjectID, :AudioDeviceIOProc], :OSStatus

    # OSStatus AudioDeviceStart(AudioObjectID       inDevice,
    #				AudioDeviceIOProcID inProcID)
    attach_function :AudioDeviceStart, [AudioObject::ObjectID, :AudioDeviceIOProcID], :OSStatus

    # OSStatus AudioDeviceStop(AudioObjectID       inDevice,
    #			       AudioDeviceIOProcID inProcID)
    attach_function :AudioDeviceStop, [AudioObject::ObjectID, :AudioDeviceIOProcID], :OSStatus

    # @endgroup

    class AudioDevice < AudioObject

	# @group AudioHardware.h: AudioDevice Properties
	PropertyPlugIn                          = 'plug'
	PropertyDeviceHasChanged                = 'diff'
	PropertyDeviceIsRunningSomewhere        = 'gone'
	ProcessorOverload                       = 'over'
	PropertyIOStoppedAbnormally             = 'stpd'
	PropertyHogMode                         = 'oink'
	PropertyBufferFrameSize                 = 'fsiz'
	PropertyBufferFrameSizeRange            = 'fsz#'
	PropertyUsesVariableBufferFrameSizes    = 'vfsz'
	PropertyIOCycleUsage                    = 'ncyc'
	PropertyStreamConfiguration             = 'slay'
	PropertyIOProcStreamUsage               = 'suse'
	PropertyActualSampleRate                = 'asrt'
	# @endgroup

	# @group Properties
	def actual_sample_rate
	    address = PropertyAddress.global_master(PropertyActualSampleRate)
	    get_property(address).get_float64(0)
	end

	def buffer_frame_size
	    address = PropertyAddress.global_master(PropertyBufferFrameSize)
	    get_property(address).get_uint32(0)
	end

	def running_somewhere?
	    address = PropertyAddress.global_master(PropertyDeviceIsRunningSomewhere)
	    0 != get_property(address).get_uint32(0)
	end
	# @endgroup

	# Start the AudioDevice
	#  If a block is provided, register it as a callback before starting the device
	#  @note The device will continue to run until `stop` is called
	def start(&block)
	    if block_given?
		io_proc_id = FFI::MemoryPointer.new(:pointer)
		status = CoreAudio.AudioDeviceCreateIOProcID(id, block, nil, io_proc_id)

		raise "Couldn't create an IO Proc #{status} => '#{[status].pack('L').reverse}'" unless status.zero? # && !@proc_id.nil?

		@proc_id = io_proc_id.get_pointer(0)
	    end

	    Thread.start do
		CoreAudio.AudioDeviceStart(id, @proc_id)
	    end
	end

	# Stop the AudioDevice and delete any registered callbacks
	def stop
	    CoreAudio.AudioDeviceStop(id, @proc_id)
	    CoreAudio.AudioDeviceDestroyIOProcID(id, @proc_id)
	end
    end
end
