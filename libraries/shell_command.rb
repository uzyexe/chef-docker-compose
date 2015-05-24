require 'open3'
require 'timeout'

module Compose
  class ShellCommand
    attr_reader :output

    def initialize(*args)
      @opts = {}
      @opts = args.pop if args.last.kind_of?(Hash)
      @command = args

      start_pipe!(@opts[:timeout] || 900)
      thread.join if output.eof?
    end

    def status
      thread.value
    end

    private
    attr_reader :thread

    def start_pipe!(timeout=900)
      pargs = [@opts[:env] || {}] << @command.join(' ')
      Timeout::timeout(timeout) do
        stdin, @output, @thread = Open3.popen2e(*pargs)
        @output.sync = true
        stdin.close
      end
    rescue Timeout::Error
      # rescued on timeout, status is non-zero anyway
    end

  end
end
