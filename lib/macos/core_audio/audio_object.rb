require_relative '../core_foundation'

module CoreAudio
    extend FFI::Library

    module AudioHardwareBase
	# AudioHardwareBase.h: AudioDevice Properties
	AudioDevicePropertyConfigurationApplication        = 'capp'
	AudioDevicePropertyDeviceUID                       = 'uid '
	AudioDevicePropertyModelUID                        = 'muid'
	AudioDevicePropertyTransportType                   = 'tran'
	AudioDevicePropertyRelatedDevices                  = 'akin'
	AudioDevicePropertyClockDomain                     = 'clkd'
	AudioDevicePropertyDeviceIsAlive                   = 'livn'
	AudioDevicePropertyDeviceIsRunning                 = 'goin'
	AudioDevicePropertyDeviceCanBeDefaultDevice        = 'dflt'
	AudioDevicePropertyDeviceCanBeDefaultSystemDevice  = 'sflt'
	AudioDevicePropertyLatency                         = 'ltnc'
	AudioDevicePropertyStreams                         = 'stm#'
	AudioObjectPropertyControlList                     = 'ctrl'
	AudioDevicePropertySafetyOffset                    = 'saft'
	AudioDevicePropertyNominalSampleRate               = 'nsrt'
	AudioDevicePropertyAvailableNominalSampleRates     = 'nsr#'
	AudioDevicePropertyIcon                            = 'icon'
	AudioDevicePropertyIsHidden                        = 'hidn'
	AudioDevicePropertyPreferredChannelsForStereo      = 'dch2'
	AudioDevicePropertyPreferredChannelLayout          = 'srnd'
    end

    module AudioHardware
	# AudioHardware.h: AudioSystemObject Properties
	PropertyDevices				    = 'dev#'
	PropertyDefaultInputDevice		    = 'dIn '
	PropertyDefaultOutputDevice		    = 'dOut'
	PropertyDefaultSystemOutputDevice	    = 'sOut'
	PropertyTranslateUIDToDevice		    = 'uidd'
	PropertyMixStereoToMono			    = 'stmo'
	PropertyPlugInList			    = 'plg#'
	PropertyTranslateBundleIDToPlugIn	    = 'bidp'
	PropertyTransportManagerList                = 'tmg#'
	PropertyTranslateBundleIDToTransportManager = 'tmbi'
	PropertyBoxList				    = 'box#'
	PropertyTranslateUIDToBox		    = 'uidb'
	PropertyProcessIsMaster                     = 'mast'
	PropertyIsInitingOrExiting                  = 'inot'
	PropertyUserIDChanged                       = 'euid'
	PropertyProcessIsAudible                    = 'pmut'
	PropertySleepingIsAllowed                   = 'slep'
	PropertyUnloadingIsAllowed                  = 'unld'
	PropertyHogModeIsAllowed                    = 'hogr'
	PropertyUserSessionIsActiveOrHeadless       = 'user'
	PropertyServiceRestarted                    = 'srst'
	PropertyPowerHint                           = 'powh'
    end

    class AudioObject
	attr_reader :id

	ObjectID = FFI::Type::UINT32
	PropertyElement = FFI::Type::UINT32
	PropertyScope = FFI::Type::UINT32
	PropertySelector = FFI::Type::UINT32

	# AudioHardwareBase.h: Basic Constants
	PropertyScopeGlobal         = 'glob'
	PropertyScopeInput          = 'inpt'
	PropertyScopeOutput         = 'outp'
	PropertyScopePlayThrough    = 'ptru'
	PropertyElementMaster       = 0

	# AudioHardwareBase.h: AudioObject Properties
	PropertyBaseClass           = 'bcls'
	PropertyClass               = 'clas'
	PropertyOwner               = 'stdv'
	PropertyName                = 'lnam'
	PropertyModelName           = 'lmod'
	PropertyManufacturer        = 'lmak'
	PropertyElementName         = 'lchn'
	PropertyElementCategoryName = 'lccn'
	PropertyElementNumberName   = 'lcnn'
	PropertyOwnedObjects        = 'ownd'
	PropertyIdentify            = 'iden'
	PropertySerialNumber        = 'snum'
	PropertyFirmwareVersion     = 'fwvn'

	# AudioHardware.h: Basic Constants
	SystemObject = 1

	def self.system
	    new(SystemObject)
	end

	def initialize(id)
	    @id = id
	end

	# @return [FFI::MemoryPointer]
	def get_property(address)
	    buffer_size = FFI::MemoryPointer.new(:uint32)
	    status = CoreAudio.AudioObjectGetPropertyDataSize(id, address, 0, nil, buffer_size)
	    raise('Could not get audio property size') unless 0 == status

	    # buffer_size is now the size of the buffer to be passed to AudioObjectGetPropertyData()
	    buffer = FFI::MemoryPointer.new(1, buffer_size.get_int32(0))
	    status = CoreAudio.AudioObjectGetPropertyData(id, address, 0, nil, buffer_size, buffer)
	    raise('Could not get the audio property data') unless 0 == status

	    buffer
	end

	def set_property(address, buffer, qualifier=nil)
	    qualifier_size = qualifier.size rescue 0
	    CoreAudio.AudioObjectSetPropertyData(id, address, 0, nil, buffer.size, buffer)
	end

	# @group Convenience Attributes
	def external?
	    not internal?
	end

	def internal?
	    transport_type == 'bltn'
	end
	# @endgroup

	# @return [String]  the name of the device
	def device_name
	    address = PropertyAddress.global_master(PropertyName)
	    get_string(address)
	end

	def device_uid
	    address = PropertyAddress.global_master(AudioHardwareBase::AudioDevicePropertyDeviceUID)
	    get_string(address)
	end

	# @return [String] a persistent identifier for the model of an AudioDevice
	def model_uid
	    address = PropertyAddress.global_master(AudioHardwareBase::AudioDevicePropertyModelUID)
	    get_string(address)
	end

	# @return [String]  the 4-character transport type identifier
	def transport_type
	    address = PropertyAddress.global_master(AudioHardwareBase::AudioDevicePropertyTransportType)
	    buffer = get_property(address)
	    buffer.get_bytes(0, buffer.size).reverse
	end

	class PropertyAddress < FFI::Struct
	    layout  :mSelector, AudioObject::PropertySelector,
		    :mScope, AudioObject::PropertyScope,
		    :mElement, AudioObject::PropertyElement

	    def self.make(selector, scope, element)
		element, scope, selector = [element, scope, selector].map {|a| a.is_a?(String) ? a.reverse.unpack('L').first : a }
		new.tap do |address|
		    address[:mSelector] = selector
		    address[:mScope] = scope
		    address[:mElement] = element
		end
	    end

	    def self.global_master(selector)
		make(selector, PropertyScopeGlobal, PropertyElementMaster)
	    end
	end

	private

	# @return [String]  the String for the addressed property
	def get_string(address)
	    buffer = get_property(address)
	    cf_string_ref = buffer.get_pointer(0)
	    CoreFoundation::CFStringRef.new(cf_string_ref).to_s
	end
    end
end
