# -----------------------------------------------------------------------------
#
# SRS database interface
#
# -----------------------------------------------------------------------------

module RGeo
  module CoordSys
    module SRSDatabase
      # A spatial reference database implementation backed by coordinate
      # system files installed as part of the proj4 library. For a given
      # Proj4Data object, you specify a single file (e.g. the epsg data
      # file), and you can retrieve records by ID number.

      class Proj4Data
        # Connect to one of the proj4 data files. You should provide the
        # file name, optionally the installation directory if it is not
        # in a typical location, and several additional options.
        #
        # These options are recognized:
        #
        # [<tt>:dir</tt>]
        #   The path for the share/proj directory that contains the
        #   requested data file. By default, the Proj4Data class will
        #   try a number of directories for you, including
        #   /usr/local/share/proj, /opt/local/share/proj, /usr/share/proj,
        #   and a few other variants. However, if you have proj4 installed
        #   elsewhere, you can provide an explicit directory using this
        #   option. You may also pass nil as the value, in which case all
        #   the normal lookup paths will be disabled, and you will have to
        #   provide the full path as the file name.
        # [<tt>:cache</tt>]
        #   If set to true, this class caches previously looked up entries
        #   so subsequent lookups do not have to reread the file. If set
        #   to <tt>:read_all</tt>, then ALL values in the file are read in
        #   and cached the first time a lookup is done. If set to
        #   <tt>:preload</tt>, then ALL values in the file are read in
        #   immediately when the database is created. Default is false,
        #   indicating that the file will be reread on every lookup.
        # [<tt>:authority</tt>]
        #   If set, its value is taken as the authority name for all
        #   entries. The authority code will be set to the identifier. If
        #   not set, then the authority fields of entries will be blank.

        def initialize(filename, opts = {})
          dir = nil
          if opts.include?(:dir)
            dir = opts[:dir]
          else
            ["/usr/local/share/proj", "/usr/local/proj/share/proj", "/usr/local/proj4/share/proj", "/opt/local/share/proj", "/opt/proj/share/proj", "/opt/proj4/share/proj", "/opt/share/proj", "/usr/share/proj"].each do |d|
              if ::File.directory?(d) && ::File.readable?(d)
                dir = d
                break
              end
            end
          end
          @path = dir ? "#{dir}/#{filename}" : filename
          @authority = opts[:authority]
          if opts[:cache]
            @cache = {}
            case opts[:cache]
            when :read_all
              @populate_state = 1
            when :preload
              _search_file(nil)
              @populate_state = 2
            else
              @populate_state = 0
            end
          else
            @cache = nil
            @populate_state = 0
          end
        end

        # Retrieve the Entry for the given ID number.

        def get(ident)
          ident = ident.to_s
          return @cache[ident] if @cache && @cache.include?(ident)
          result = nil
          if @populate_state == 0
            data = _search_file(ident)
            result = Entry.new(ident, authority: @authority, authority_code: @authority ? ident : nil, name: data[1], proj4: data[2]) if data
            @cache[ident] = result if @cache
          elsif @populate_state == 1
            _search_file(nil)
            result = @cache[ident]
            @populate_state = 2
          end
          result
        end

        # Clear the cache if one exists.

        def clear_cache
          @cache.clear if @cache
          @populate_state = 1 if @populate_state == 2
        end

        def _search_file(ident) # :nodoc:
          ::File.open(@path) do |file|
            cur_name = nil
            cur_ident = nil
            cur_text = nil
            file.each do |line|
              line.strip!
              if (comment_delim = line.index('#'))
                cur_name = line[comment_delim + 1..-1].strip
                line = line[0..comment_delim - 1].strip
              end
              unless cur_ident
                if line =~ /^<(\w+)>(.*)/
                  cur_ident = Regexp.last_match(1)
                  cur_text = []
                  line = Regexp.last_match(2).strip
                end
              end
              next unless cur_ident
              if line[-2..-1] == "<>"
                cur_text << line[0..-3].strip
                cur_text = cur_text.join(" ")
                if ident.nil?
                  @cache[ident] = Entry.new(ident, authority: @authority, authority_code: @authority ? id : nil, name: cur_name, proj4: cur_text)
                end
                return [ident, cur_name, cur_text] if cur_ident == ident
                cur_ident = nil
                cur_name = nil
                cur_text = nil
              else
                cur_text << line
              end
            end
          end
          nil
        end
      end
    end
  end
end
