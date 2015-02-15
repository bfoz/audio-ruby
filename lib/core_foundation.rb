require 'ffi'

module CoreFoundation
    extend FFI::Library
    ffi_lib '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation'

    typedef :pointer, :CFStringRef

    if FFI::Platform::ARCH == 'x86_64'
	CFIndex = FFI::Type::LONG_LONG
    else
	CFIndex = FFI::Type::LONG
    end

    # CFString.h
    CFStringEncoding = enum :uint32,
			:MacRoman, 0,
			:WindowsLatin1, 0x0500,	    # ANSI codepage 1252
			:ISOLatin1, 0x0201,	    # ISO 8859-1
			:NextStepLatin, 0x0B01,	    # NextStep encoding
			:ASCII, 0x0600,		    # 0..127 (in creating CFString, values greater than 0x7F are treated as corresponding Unicode value)
			:Unicode, 0x0100,	    # kTextEncodingUnicodeDefault  + kTextEncodingDefaultFormat (aka kUnicode16BitFormat)
			:UTF8, 0x08000100,	    # kTextEncodingUnicodeDefault + kUnicodeUTF8Format
			:NonLossyASCII, 0x0BFF,	    # 7bit Unicode variants used by Cocoa & Java
			:UTF16, 0x0100,		    # kTextEncodingUnicodeDefault + kUnicodeUTF16Format (alias of kCFStringEncodingUnicode)
			:UTF16BE, 0x10000100,	    # kTextEncodingUnicodeDefault + kUnicodeUTF16BEFormat
			:UTF16LE, 0x14000100,	    # kTextEncodingUnicodeDefault + kUnicodeUTF16LEFormat
			:UTF32, 0x0c000100,	    # kTextEncodingUnicodeDefault + kUnicodeUTF32Format
			:UTF32BE, 0x18000100,	    # kTextEncodingUnicodeDefault + kUnicodeUTF32BEFormat
			:UTF32LE, 0x1c000100,	    # kTextEncodingUnicodeDefault + kUnicodeUTF32LEFormat
			:Invalid, 0xffffffff	    # Invalid Encoding

    class CFRange < FFI::Struct
	layout :location, CFIndex,
	       :length, CFIndex

	def self.make(location:0, length:0)
	    new.tap do |range|
		range[:location] = location
		range[:length] = length
	    end
	end
    end

    class CFStringRef < FFI::Pointer
	# @return [CFIndex] the length of the referenced CFString
	def length
	    CoreFoundation.CFStringGetLength(self)
	end

	# @return [CFIndex] the maximum size of the buffer that will hold the string
	def max_size
	    CoreFoundation.CFStringGetMaximumSizeForEncoding(length, CFStringEncoding[:UTF8])
	end

	# @return [String]  the CFString, converted to a UTF-8 string
	def to_s
	    buffer = FFI::MemoryPointer.new(:char, max_size)
	    used_bytes = FFI::MemoryPointer.new(CFIndex)
	    CoreFoundation.CFStringGetBytes(self,
					    CFRange.make(location:0, length:length),
					    CFStringEncoding[:UTF8],
					    0,
					    false,
					    buffer,
					    buffer.size,
					    used_bytes)

	    used_bytes = if CFIndex == CoreFoundation.find_type(:long_long)
		used_bytes.read_long_long
	    else
		used_bytes.read_long
	    end

	    buffer.read_string(used_bytes).force_encoding(Encoding::UTF_8)
	end
    end

    # CFIndex CFStringGetBytes(CFStringRef theString, CFRange range, CFStringEncoding encoding, UInt8 lossByte, Boolean isExternalRepresentation, UInt8 *buffer, CFIndex maxBufLen, CFIndex *usedBufLen)
    attach_function :CFStringGetBytes, [:CFStringRef, CFRange.by_value, CFStringEncoding, :uint8, :bool, :buffer_out, CFIndex, :buffer_out], CFIndex

    # CFIndex CFStringGetLength(CFStringRef theString)
    attach_function :CFStringGetLength, [:CFStringRef], CFIndex

    # CFIndex CFStringGetMaximumSizeForEncoding(CFIndex length, CFStringEncoding encoding)
    attach_function :CFStringGetMaximumSizeForEncoding, [CFIndex, CFStringEncoding], CFIndex
end