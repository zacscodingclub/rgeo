# -----------------------------------------------------------------------------
#
# Common methods for Point features
#
# -----------------------------------------------------------------------------

module RGeo
  module ImplHelper # :nodoc:
    module BasicPointMethods # :nodoc:
      def initialize(factory, x, y, *extra)
        _set_factory(factory)
        @x = x.to_f
        @y = y.to_f
        @z = factory.property(:has_z_coordinate) ? extra.shift.to_f : nil
        @m = factory.property(:has_m_coordinate) ? extra.shift.to_f : nil
        if extra.size > 0
          raise ::ArgumentError, "Too many arguments for point initializer"
        end
        _validate_geometry
      end

      def x
        @x
      end

      def y
        @y
      end

      def z
        @z
      end

      def m
        @m
      end

      def dimension
        0
      end

      def geometry_type
        Feature::Point
      end

      def is_empty?
        false
      end

      def is_simple?
        true
      end

      def envelope
        self
      end

      def boundary
        factory.collection([])
      end

      def convex_hull
        self
      end

      def equals?(rhs)
        return false unless rhs.is_a?(self.class) && rhs.factory == factory
        case rhs
        when Feature::Point
          rhs.x == @x && rhs.y == @y
        when Feature::LineString
          rhs.num_points > 0 && rhs.points.all? { |elem| equals?(elem) }
        when Feature::GeometryCollection
          rhs.num_geometries > 0 && rhs.all? { |elem| equals?(elem) }
        else
          false
        end
      end

      def rep_equals?(rhs)
        rhs.is_a?(self.class) && rhs.factory.eql?(@factory) && @x == rhs.x && @y == rhs.y && @z == rhs.z && @m == rhs.m
      end

      def hash
        @hash ||= [factory, geometry_type, @x, @y, @z, @m].hash
      end

      def _copy_state_from(obj) # :nodoc:
        super
        @x = obj.x
        @y = obj.y
        @z = obj.z
        @m = obj.m
      end

      def coordinates
        [x, y].tap do |coords|
          coords << z if factory.property(:has_z_coordinate)
          coords << m if factory.property(:has_m_coordinate)
        end
      end
    end
  end
end
