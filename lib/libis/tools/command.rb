# encoding: utf-8
require 'open3'

module LIBIS
  module Tools

    module Command

      # Run an external program and return status, stdout and stderr.
      #
      #
      # @param [String] cmd program name
      # @param [Array<String>] opts optional list of command line arguments
      # @return [Hash] a Hash with:
      #         * +:status+ : the exit status of the command
      #         * +:out+ : the stdout output of the command
      #         * +:err+ : the stderr output of the command
      def self.run(cmd, *opts)

        result = {}
        Open3.popen3(cmd, *opts) do |_, output, error, thread|
          result[:out] = output.read.split("\n").map(&:chomp)
          result[:err] = error.read.split("\n").map(&:chomp)
          result[:status] = thread.value.exitstatus rescue nil
        end

        result

      end
    end

  end
end
