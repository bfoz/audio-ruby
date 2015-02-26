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
	# @group AudioHardwareBase.h: AudioDevice Properties
	PropertyConfigurationApplication        = 'capp'
	PropertyDeviceUID                       = 'uid '
	PropertyModelUID                        = 'muid'
	PropertyTransportType                   = 'tran'
	PropertyRelatedDevices                  = 'akin'
	PropertyClockDomain                     = 'clkd'
	PropertyDeviceIsAlive                   = 'livn'
	PropertyDeviceIsRunning                 = 'goin'
	PropertyDeviceCanBeDefaultDevice        = 'dflt'
	PropertyDeviceCanBeDefaultSystemDevice  = 'sflt'
	PropertyLatency                         = 'ltnc'
	PropertyStreams                         = 'stm#'
	PropertyControlList                     = 'ctrl'
	PropertySafetyOffset                    = 'saft'
	PropertyNominalSampleRate               = 'nsrt'
	PropertyAvailableNominalSampleRates     = 'nsr#'
	PropertyIcon                            = 'icon'
	PropertyIsHidden                        = 'hidn'
	PropertyPreferredChannelsForStereo      = 'dch2'
	PropertyPreferredChannelLayout          = 'srnd'
	# @endgroup

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

	def buffer_frame_size
	    address = PropertyAddress.global_master(PropertyBufferFrameSize)
	    get_property(address).get_uint32(0)
	end

	# @return [Bool]    true if the device is running
	def running?
	    address = PropertyAddress.global_master(PropertyDeviceIsRunning)
	    0 != get_property(address).get_uint32(0)
	end

	def running_somewhere?
	    address = PropertyAddress.global_master(PropertyDeviceIsRunningSomewhere)
	    0 != get_property(address).get_uint32(0)
	end

	# @group Sample Rate

	# @return [Float]   the measured sample rate in Hertz
	def actual_sample_rate
	    address = PropertyAddress.global_master(PropertyActualSampleRate)
	    get_property(address).get_float64(0)
	end

	# @return [Array<Number,Range>]	the available sampling rates, or sample-rate-ranges
	def available_sample_rates
	    address = PropertyAddress.global_master(PropertyAvailableNominalSampleRates)
	    buffer = get_property(address)
	    buffer = buffer.get_array_of_float64(0, buffer.size / FFI::Type::DOUBLE.size)

	    # Convert the range pairs into actual Ranges, unless the Range is empty
	    buffer.each_slice(2).map {|a,b| (a==b) ? a : (a..b)}
	end

	# @return [Float]   the device's nominal sample rate
	def sample_rate
	    address = PropertyAddress.global_master(PropertyNominalSampleRate)
	    get_property(address).get_float64(0)
	end

	# @param rate [Float]	the new sample rate in Hertz
	def sample_rate=(rate)
	    address = PropertyAddress.global_master(PropertyNominalSampleRate)
	    ffi_rate = FFI::MemoryPointer.new(:double)
	    ffi_rate.put_float64(0, rate)
	    status = set_property(address, ffi_rate)
	    raise "status #{status} => '#{[status].pack('L').reverse}'" unless 0 == status
	end
	# @endgroup
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
