# frozen_string_literal: true

require "rmodbus"

module ABB
  # Allows interaction with the variable frequency drive
  class Drive
    attr_reader :slave
    # control words
    attr_reader :control_word

    attr_reader :power, :reference1, :reference1_max, :speed, :frequency, :current, :runtime, :energy_meter, :time_meter

    def initialize(uri, slave_id = 1)
      uri = URI.parse(uri)

      io = case uri.scheme
           when "tcp"
             require "socket"
             TCPSocket.new(uri.host, uri.port)
           when "telnet", "rfc2217"
             require "net/telnet/rfc2217"
             Net::Telnet::RFC2217.new(uri.host,
                                      port: uri.port || 23,
                                      baud: 9600,
                                      stop_bits: 2,
                                      data_bits: 8,
                                      parity: :none)
           else
             require "ccutrer-serialport"
             CCutrer::SerialPort.new(uri.path,
                                     baud: 9600,
                                     parity: :none,
                                     data_bits: 8,
                                     stop_bits: 2)
           end

      client = ::ModBus::RTUClient.new(io)
      @slave = client.with_slave(slave_id)
      @reference1_max = @slave.holding_registers[1104]
    end

    def poll
      @control_word = slave.holding_registers[0]
      @reference1 = slave.holding_registers[1].to_f / 20_000 * reference1_max
      @runtime = slave.holding_registers[113]
      @energy_meter = slave.holding_registers[140] * 1000 + slave.holding_registers[114]
      @time_meter = slave.holding_registers[142] * 86400 + slave.holding_registers[143]
      @control_board_temperature = slave.holding_registers[149].to_f / 10
      @speed = slave.holding_registers[100]
      @frequency = slave.holding_registers[102].to_f / 10
      @current = slave.holding_registers[103].to_f / 10

      @power = @control_word != 0
    end

    def power=(value)
      value ? on : off
    end

    def on?
      power
    end

    def off?
      !power
    end

    def on
      self.control_word = 0x0006
      sleep(0.1)
      self.control_word = 0x0007
      self.control_word = 0x000f
      self.control_word = 0x002f
      self.control_word = 0x006f
    end

    def off
      self.control_word = 0x0000
    end

    def reference1=(value)
      scaled_value = (value.clamp(0..reference1_max).to_f / reference1_max * 20_000).to_i
      return off if scaled_value.zero?

      slave.holding_registers[1] = scaled_value
      on unless on?
    rescue =>e 
      puts e
    end

    def control_word=(value)
      slave.holding_registers[0] = @control_word = value
    end
  end
end
