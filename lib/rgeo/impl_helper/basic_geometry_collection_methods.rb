# -----------------------------------------------------------------------------
#
# Common methods for GeometryCollection features
#
# -----------------------------------------------------------------------------

module RGeo
  module ImplHelper # :nodoc:
    module BasicGeometryCollectionMethods # :nodoc:
      def initialize(factory, elements)
        _set_factory(factory)
        @elements = elements.map do |elem|
          elem = Feature.cast(elem, factory)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        _validate_geometry
      end

      def num_geometries
        @elements.size
      end

      def geometry_n(n)
        n < 0 ? nil : @elements[n]
      end

      def [](n)
        @elements[n]
      end

      def each(&block)
        @elements.each(&block)
      end

      def dimension
        unless defined?(@dimension)
          @dimension = -1
          @elements.each do |elem|
            dim = elem.dimension
            @dimension = dim if @dimension < dim
          end
        end
        @dimension
      end

      def geometry_type
        Feature::GeometryCollection
      end

      def is_empty?
        @elements.size == 0
      end

      def rep_equals?(rhs)
        if rhs.is_a?(self.class) && rhs.factory.eql?(@factory) && @elements.size == rhs.num_geometries
          rhs.each_with_index { |p, i| return false unless @elements[i].rep_equals?(p) }
        else
          false
        end
      end

      def hash
        @hash ||= begin
          hash = [factory, geometry_type].hash
          @elements.inject(hash) { |h, g| (1_664_525 * h + g.hash).hash }
        end
      end

      def _copy_state_from(obj) # :nodoc:
        super
        @elements = obj._elements
      end

      def _elements # :nodoc:
        @elements
      end
    end

    module BasicMultiLineStringMethods  # :nodoc:
      def initialize(factory, elements)
        _set_factory(factory)
        @elements = elements.map do |elem|
          elem = Feature.cast(elem, factory, Feature::LineString, :keep_subtype)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        _validate_geometry
      end

      def geometry_type
        Feature::MultiLineString
      end

      def is_closed?
        all?(&:is_closed?)
      end

      def length
        @elements.inject(0.0) { |sum, obj| sum + obj.length }
      end

      def _add_boundary(hash, point)  # :nodoc:
        hval = [point.x, point.y].hash
        (hash[hval] ||= [point, 0])[1] += 1
      end

      def boundary
        hash = {}
        @elements.each do |line|
          if !line.is_empty? && !line.is_closed?
            _add_boundary(hash, line.start_point)
            _add_boundary(hash, line.end_point)
          end
        end
        array = []
        hash.each do |_hval_, data|
          array << data[0] if data[1].odd?
        end
        factory.multi_point([array])
      end

      def coordinates
        @elements.map(&:coordinates)
      end
    end

    module BasicMultiPointMethods # :nodoc:
      def initialize(factory, elements)
        _set_factory(factory)
        @elements = elements.map do |elem_|
          elem = Feature.cast(elem, factory, Feature::Point, :keep_subtype)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        _validate_geometry
      end

      def geometry_type
        Feature::MultiPoint
      end

      def boundary
        factory.collection([])
      end

      def coordinates
        @elements.map(&:coordinates)
      end
    end

    module BasicMultiPolygonMethods # :nodoc:
      def initialize(factory, elements)
        _set_factory(factory)
        @elements = elements.map do |elem_|
          elem = Feature.cast(elem, factory, Feature::Polygon, :keep_subtype)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        _validate_geometry
      end

      def geometry_type
        Feature::MultiPolygon
      end

      def area
        @elements.inject(0.0) { |sum, obj| sum + obj.area }
      end

      def boundary
        array = []
        @elements.each do |poly|
          array << poly.exterior_ring unless poly.is_empty?
          array.concat(poly.interior_rings)
        end
        factory.multi_line_string(array)
      end

      def coordinates
        @elements.map(&:coordinates)
      end
    end
  end
end
