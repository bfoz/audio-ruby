module AudioToolbox
    class AudioConverterRef < FFI::Pointer
	attr_accessor :from
	attr_accessor :to

	# @group AudioConverter.h
	PrimeMethod                          = 'prmm'
	# @endgroup

	# @param buffer	[AudioBufferList]   the list of buffers to be converted
	# @return [AudioBufferList] the converted data
	def convert(buffer)
	    num_from_packets = (buffer.bytesize / from[:mBytesPerPacket]).floor
	    remaining_packets = num_from_packets

	    block = Proc.new do |_, num_packets, buffer_list, _|
		unless remaining_packets.zero?
		    buffer_list = CoreAudio::AudioBufferList.new(buffer_list)
		    buffer_list.buffers.first[:mData] = buffer.buffers.first[:mData]
		    buffer_list.buffers.first[:mDataByteSize] = buffer.buffers.first[:mDataByteSize]
		end

		# Report the number of packets actually sent
		num_packets.put_uint32(0, remaining_packets)

		remaining_packets = 0   # No more packets remaining

		0   # All is well
	    end

	    bytes_per_packet = to[:mBytesPerPacket]
	    num_output_packets = (num_from_packets * to.sample_rate / from.sample_rate).floor

	    output_list = CoreAudio::AudioBufferList.buffer_list(size:bytes_per_packet * num_output_packets)
	    raise("No buffer list") unless output_list

	    num_packets = FFI::MemoryPointer.new(:uint32).put_uint32(0, num_output_packets)
	    status = AudioToolbox.AudioConverterFillComplexBuffer(self, block, nil, num_packets, output_list, nil)
	    raise("Convert failed: '#{[status].pack('L').reverse}'") unless status.zero?

	    output_list
	end

	# @param method	[Symbol]    :pre, :normal, or :none
	def prime_method=(method=:normal)
	    method = case method
		when :pre	then 0
		when :normal	then 1
		when :none	then 2
	    end
	    data = FFI::MemoryPointer.new(:uint32).put_uint32(0, method)
	    AudioToolbox.AudioConverterSetProperty(self, PrimeMethod.reverse.unpack('L').first, 4, data)
	end
    end
end
