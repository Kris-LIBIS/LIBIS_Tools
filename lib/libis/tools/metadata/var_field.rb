# coding: utf-8

require 'libis/tools/assert'

require_relative 'parser/subfield_criteria_parser'

module Libis
  module Tools
    module Metadata

      # Helper class implementing a variable field for MARC
      class VarField

        attr_reader :tag
        attr_reader :ind1
        attr_reader :ind2
        attr_reader :subfield_data

        # Create new variable field with given tag and indicators
        # @param [String] tag tag
        # @param [String] ind1 first indicator. nil will be translated into empty string.
        # @param [String] ind2 second indicator. nil will be translated into empty string.
        def initialize(tag, ind1, ind2)
          @tag = tag
          @ind1 = ind1 || ''
          @ind2 = ind2 || ''
          @subfield_data = Hash.new { |h, k| h[k] = Array.new   }
        end

        # Add subfield to variable field
        # @param [String] name subfield indicator without '$'
        # @param [String] value content of the subfield
        def add_subfield(name, value)
          @subfield_data[name] << value
        end

        # dump the contents
        #
        # @return [String] debug output to inspect the contents of the VarField
        def dump
          output = "#{@tag}:#{@ind1}:#{@ind2}:\n"
          @subfield_data.each { |s, t| output += "\t#{s}:#{t}\n" }
          output
        end

        # dump the contents
        #
        # @return [String] debug output to inspect the contents of the VarField - Single line version
        def dump_line
          output = "#{@tag}:#{@ind1}:#{@ind2}:"
          @subfield_data.each { |s, t| output += "$#{s}#{t}" }
          output
        end

        # list the subfield codes
        #
        # @return [Array] a list of all subfield codes
        def keys
          @subfield_data.keys
        end

        # get the first (or only) subfield value for the given code
        #
        # @return [String] the first or only entry of a subfield or nil if not present
        # @param s [Character] the subfield code
        def subfield(s)
          subfield_array(s).first
        end

        # get a list of all subfield values for a given code
        #
        # @return [Array] all the entries of a repeatable subfield
        # @param s [Character] the subfield code
        def subfield_array(s)
          assert(s.is_a?(String) && (s =~ /^[\da-z]$/) == 0, 'method expects a lower case alphanumerical char')
          @subfield_data.has_key?(s) ? @subfield_data[s].dup : []
        end

        # get a list of the first subfield values for all the codes in the given string
        #
        # @return [Array] list of the first or only entries of all subfield codes in the input string
        # @param s [String] subfield code specification (see match)
        #
        # The subfield codes are cleaned (see criteria_to_array)
        def subfields(s)
          assert(s.is_a?(String), 'method expects a string')
          return [] unless (match_array = match(s))
          criteria_to_array(match_array.join(' ')).collect { |i| send(:subfield, i) }.flatten.compact
        end

        # get a list of all the subfield values for all the codes in the given string
        #
        # @return [Array] list of the all the entries of all subfield codes in the input string
        # @param s [String] subfield code criteria (see match)
        #
        # The subfield codes are cleaned (see criteria_to_array)

        def subfields_array(s)
          assert(s.is_a?(String), 'method expects a string')
          return [] unless (match_array = match(s))
          criteria_to_array(match_array.join(' ')).collect { |i| send(:subfield_array, i) }.flatten.compact
        end

        # check if the current VarField matches the given subfield criteria.
        #
        # @return [String] The matching part(s) of the criteria or nil if no match
        # @param criteria [String] subfield criteria: sequence of alternative set of subfield codes that should-shouldn't be present
        #
        # The subfield criteria consists of groups of characters. At least one of these groups should match for the test to succeed
        # Within the group sets of codes may be divided by a hyphen (-). The first set of codes must all be present;
        # the second set of codes must all <b>not</b> be present. Either set may be empty.
        #
        # Examples:
        #   'ab'      matches '$a...$b...'            => ['ab']
        #                     '$a...$b...$c...'       => ['ab']
        #             but not '$a...'                 => nil      # ($b missing)
        #                     '$b...'                 => nil      # ($a missing)
        #   'a b'     matches '$a...'                 => ['a']
        #                     '$b...'                 => ['b']
        #                     '$a...$b...'            => ['a', 'b']
        #                     '$a...$b...$c...'       => ['a', 'b']
        #             but not '$c...'                 => nil      # ($a or $b must be present)
        #   'abc-d'   matches '$a..,$b...$c...'       => ['abc-d']
        #                     '$a..,$b...$c...$e...'  => ['abc-d']
        #             but not '$a...$b...$e...'       => nil      # ($c missing)
        #                     '$a...$b...$c...$d...'  => nil      # ($d should not be present)
        #   'a-b b-a' matches '$a...'                 => ['a-b']
        #                     '$a...$c...'            => ['a-b']
        #                     '$b...'                 => ['b-a']
        #                     '$b...$c...'            => ['b-a']
        #             but not '$a...$b...'            => nil
        #   'a-b c-d' matches '$a...'                 => ['a-b']
        #                     '$a...$c...'            => ['a-b', 'c-d']
        #                     '$a...$b...$c...'       => ['c-d']
        #                     '$b...$c...'            => ['c-d']
        #             but not '$a...$b...'            => nil
        #                     '$c...$d...'            => nil
        #                     '$b...$c...$d...'       => nil
        #                     '$a...$b...$c...$d...'  => nil
        def match(criteria)
          begin
            parser = Libis::Tools::Metadata::SubfieldCriteriaParser.new
            tree = parser.parse(criteria)
            return [] if tree.is_a? String
            tree = [tree] unless tree.is_a? Array
            result = tree.map do |selection|
              next unless parser.match_selection(selection, keys)
              parser.selection_to_s(selection)
            end.compact
            return nil if result.empty?
            result
          rescue Parslet::ParseFailed => failure
            failure.cause.set_label(criteria)
            raise failure
          end
        end

        private

        # @return [Array] cleaned up version of the input string
        # @param subfields [String] subfield code specification
        # cleans the subfield code specification and splits it into an array of characters
        # Duplicates will be removed from the array and the order will be untouched.
        def criteria_to_array(subfields)

          # note that we remove the '-xxx' part as it is only required for matching
          subfields.gsub(/ |-\w*/, '').split('').uniq
        end

        def sort_helper(x)
          # make sure that everything below 'A' is higher than 'z'
          # note that this only works for numbers, but that is fine in our case.
          x < 'A' ? (x.to_i + 123).chr : x
        end

        # implementation for methods for retrieving subfield values
        #
        # The methods start with a single character: the operation
        # 'f' for retrieving only the first occurence of the subfield
        # 'a' for retrieving all the subfield values for each of the given subfields
        # if omitted, 'f' is assumed
        #
        # Then a '_' acts as a subdivider between the operation and the subfield(s). It must always be present, even
        # if the operation is omitted.
        #
        # The last past is a sequence of subfield codes that should be used for selecting the values. The order in which the
        # subfields are listed is respected in the resulting array of values.
        #
        # Examples:
        #
        #   t = VarField.new('100', '', '',
        #                    { 'a' => %w'Name NickName',
        #                      'b' => %w'LastName MaidenName',
        #                      'c' => %w'eMail',
        #                      '1' => %w'Age',
        #                      '9' => %w'Score'})
        #
        #   # >> 100##$aName$aNickName$bLastName$bMaidenName$ceMail$1Age$9Score <<
        #
        #   t._1ab => ['Age', 'Name', 'LastName']
        #   # equivalent to: t.f_1av or t.fields('1ab')
        #
        #   t.a_9ab => ['Score', 'Name', 'NickName', 'LastName', 'MaidenName']
        #   # equivalent to: t.fields_array('9ab')
        #
        # Note that it is not possible to use a fieldspec for the sequence of subfield codes. Spaces and '-' are not allowed
        # in method calls. If you want this, use the #subfield(s) and #subfield(s)_array methods.
        #
        def method_missing(name, *args)
          operation, subfields = name.to_s.split('_')
          assert(subfields.size > 0, 'need to specify at least one subfield')
          operation = 'f' if operation.empty?
          # convert subfield list to fieldspec
          subfields = subfields.split('').join(' ')
          case operation
            when 'f'
              if subfields.size > 1
                operation = :subfields
              else
                operation = :subfield
              end
            when 'a'
              if subfields.size > 1
                operation = :subfields_array
              else
                operation = :subfield_array
              end
            else
              throw "Unknown method invocation: '#{name}' with: #{args}"
          end
          send(operation, subfields)
        end

        def to_ary
          nil
        end

      end

    end
  end
end
