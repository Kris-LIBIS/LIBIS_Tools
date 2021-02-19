# Extension class
class String

  # from activesupport
  def camelize(first_letter = :upper)
    if first_letter == :upper
      gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      self[0..0].downcase + camelize[1..-1]
    end
  end unless method_defined? :camelize

  def constantize
    names = split('::')
    names.shift if names.empty? || names.first.empty?

    constant = Object
    names.each do |name|
      constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
    end
    constant
  end unless method_defined? :constantize

  def dasherize
    gsub(/_/, '-')
  end unless method_defined? :dasherize

  def demodulize
    gsub(/^.*::/, '')
  end unless method_defined? :demodulize

  def underscore
    gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
  end unless method_defined? :underscore

  # Check if string is empty
  BLANK_RE = /\A[[:space:]]^\z/.freeze
  def blank?
    empty? || BLANK_RE.match?(self)
  end

  # Create sortable object from string. Supports better natural sorting.
  def sort_form
    result = []
    matcher = /^(\D*)(\d*)(.*)$/
    self.split('.').each { |s|
      while !s.empty? and (x = matcher.match s)
        a = x[1].to_s.strip
        b = a.gsub(/[ _]/, '')
        result << [b.downcase, b, a]
        result << x[2].to_i
        s = x[3]
      end
    }
    result
  end unless method_defined? :sort_form

  # Quote string for command-line use.
  def quote
    '\"' + self.gsub(/"/) { |s| '\\' + s[0] } + '\"'
  end unless method_defined? :quote

  # Escape string for use in Regular Expressions
  def escape_for_regexp
    self.gsub(/[\.\+\*\(\)\{\}\|\/\\\^\$"']/) { |s| '\\' + s[0].to_s }
  end

  # Escape double quotes for usage in code strings.
  def escape_for_string
    self.gsub(/"/) { |s| '\\' + s[0].to_s }
  end

  # Escape double quotes for usage in passing through scripts
  def escape_for_cmd
    self.gsub(/"/) { |s| '\\\\\\' + s[0].to_s }
  end

  # Escape single quotes for usage in SQL statements
  def escape_for_sql
    self.gsub(/'/) { |s| ($` == '' || $' == '' ? '' : '\'') + s[0].to_s }
  end

  def dot_net_clean
    self.gsub /^(\d+|error|float|string);\\?#/, ''
  end

  # Convert whitespace into underscores
  def remove_whitespace
    self.gsub(/\s/, '_')
  end

  # Escape all not-printabe characters in hex format
  def encode_visual(regex = nil)
    regex ||= /\W/
    self.gsub(regex) { |c| '_x' + '%04x' % c.unpack('U')[0] + '_'}
  end unless method_defined? :encode_visual

  # Convert all not-printable characters encoded in hex format back to original
  def decode_visual
    self.gsub(/_x([0-9a-f]{4})_/i) { [$1.to_i(16)].pack('U') }
  end unless method_defined? :decode_visual

  # Align a multi-line string to the left by removing as much spaces from the left as possible.
  def align_left
    string = dup
    relevant_lines = string.split(/\r\n|\r|\n/).select { |line| line.size > 0 }
    indentation_levels = relevant_lines.map do |line|
      match = line.match(/^( +)[^ ]+/)
      match ? match[1].size : 0
    end
    indentation_level = indentation_levels.min
    string.gsub! /^#{' ' * indentation_level}/, '' if indentation_level > 0
    string
  end unless method_defined? :align_left

end

# Extension class
class NilClass

  # Allow nil.blank? so that blank? can be applied without errors.
  def blank?
    true
  end
end