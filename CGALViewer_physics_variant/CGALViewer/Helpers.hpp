//
//  PointGenerator.cpp
//  CGALViewer
//
//  Created by Paul Agron on 1/23/17.
//  Copyright © 2017 Paul Agron. All rights reserved.
//

#pragma once

#include "PointGenerator.hpp"
#include <CGAL/Polyhedron_incremental_builder_3.h>

using namespace std;


namespace adb {
    
    template <class HDS> class BuildCube : public CGAL::Modifier_base<HDS> {
    public:
        BuildCube() {}
        void operator()( HDS& hds) {
            double R = 10;
            // Postcondition: hds is a valid polyhedral surface.
            CGAL::Polyhedron_incremental_builder_3<HDS> B( hds, true);
            B.begin_surface( 8, 6, 0);
            typedef typename HDS::Vertex   Vertex;
            typedef typename Vertex::Point Point;
            
            B.add_vertex( Point( -R, -R, -R));
            B.add_vertex( Point( R, -R, -R));
            B.add_vertex( Point( R, R, -R));
            B.add_vertex( Point( -R, R, -R));
            
            B.add_vertex( Point( -R, -R, R));
            B.add_vertex( Point( R, -R, R));
            B.add_vertex( Point( R, R, R));
            B.add_vertex( Point( -R, R, R));
            
            
            B.begin_facet();
            B.add_vertex_to_facet( 0);
            B.add_vertex_to_facet( 3);
            B.add_vertex_to_facet( 2);
            B.add_vertex_to_facet( 1);
            B.end_facet();
            
            B.begin_facet();
            B.add_vertex_to_facet( 4);
            B.add_vertex_to_facet( 5);
            B.add_vertex_to_facet( 6);
            B.add_vertex_to_facet( 7);
            B.end_facet();
            
            B.begin_facet();
            B.add_vertex_to_facet( 0);
            B.add_vertex_to_facet( 4);
            B.add_vertex_to_facet( 7);
            B.add_vertex_to_facet( 3);
            B.end_facet();
            
            B.begin_facet();
            B.add_vertex_to_facet( 1);
            B.add_vertex_to_facet( 2);
            B.add_vertex_to_facet( 6);
            B.add_vertex_to_facet( 5);
            B.end_facet();
            
            B.begin_facet();
            B.add_vertex_to_facet( 2);
            B.add_vertex_to_facet( 3);
            B.add_vertex_to_facet( 7);
            B.add_vertex_to_facet( 6);
            B.end_facet();
            
            B.begin_facet();
            B.add_vertex_to_facet( 0);
            B.add_vertex_to_facet( 1);
            B.add_vertex_to_facet( 5);
            B.add_vertex_to_facet( 4);
            B.end_facet();
            
            B.end_surface();
        }
    };
    
    template <class HDS> class BuildTetra : public CGAL::Modifier_base<HDS> {
    public:
        BuildTetra() {}
        void operator()( HDS& hds) {
            // Postcondition: hds is a valid polyhedral surface.
            CGAL::Polyhedron_incremental_builder_3<HDS> B( hds, true);
            B.begin_surface( 4, 4, 0);
            typedef typename HDS::Vertex   Vertex;
            typedef typename Vertex::Point Point;
            B.add_vertex( Point( 0, 0, 0));
            B.add_vertex( Point( 0, 4, 0));
            B.add_vertex( Point( 2, 4, 0));
            B.add_vertex( Point( 2, 2, 15));
            
            B.begin_facet();
            B.add_vertex_to_facet( 0);
            B.add_vertex_to_facet( 2);
            B.add_vertex_to_facet( 1);
            B.end_facet();
            
            B.begin_facet();
            B.add_vertex_to_facet( 0);
            B.add_vertex_to_facet( 3);
            B.add_vertex_to_facet( 2);
            B.end_facet();
            
            
            B.begin_facet();
            B.add_vertex_to_facet( 0);
            B.add_vertex_to_facet( 1);
            B.add_vertex_to_facet( 3);
            B.end_facet();
            
            B.begin_facet();
            B.add_vertex_to_facet( 1);
            B.add_vertex_to_facet( 2);
            B.add_vertex_to_facet( 3);
            B.end_facet();
            
            
            
            B.end_surface();
        }
    };
}




namespace CGAL {

template <typename X>
    class Convex_hull_traits_3<adb::K, X> : public Convex_hull_traits_base_3<adb::K, X>
{
public:
    typedef adb::K                                    R;
    typedef Convex_hull_traits_3<R,X>  Self;
    typedef typename R::Point_3                    Point_3;
    typedef typename R::Segment_3                  Segment_3;
    typedef typename R::Triangle_3                 Triangle_3;
    typedef Point_triple<R>                        Plane_3;
    typedef typename R::Vector_3                   Vector_3;
    
//    typedef CGAL::Polyhedron_3<R>                  Polyhedron_3;
    typedef adb::Polyhedron_3                  Polyhedron_3;
    
    typedef typename R::Construct_segment_3        Construct_segment_3;
    typedef typename R::Construct_ray_3            Construct_ray_3;
    
    class Construct_plane_3 {
    public:
        Plane_3 operator ()(const Point_3& p, const Point_3& q, const Point_3& r)
        {
            return Plane_3(p,q,r);
        }
    };
    
    typedef typename R::Construct_triangle_3       Construct_triangle_3;
    typedef typename R::Construct_centroid_3       Construct_centroid_3;
    typedef Point_triple_construct_orthogonal_vector_3<Self, R>
    Construct_orthogonal_vector_3;
    
    typedef typename R::Equal_3                    Equal_3;
    typedef typename R::Orientation_3              Orientation_3;
    typedef typename R::Collinear_3                Collinear_3;
    typedef typename R::Coplanar_3                 Coplanar_3;
    typedef typename R::Less_distance_to_point_3   Less_distance_to_point_3;
    
    typedef typename Convex_hull_traits_base_3<adb::K, X>::Has_on_positive_side_3 Has_on_positive_side_3;
    typedef typename Convex_hull_traits_base_3<adb::K, X>::Less_signed_distance_to_plane_3 Less_signed_distance_to_plane_3;
    
    // required for degenerate case of all points coplanar
    typedef CGAL::Projection_traits_xy_3<R>         Traits_xy_3;
    typedef CGAL::Projection_traits_yz_3<R>         Traits_yz_3;
    typedef CGAL::Projection_traits_xz_3<R>         Traits_xz_3;
    typedef typename R::Construct_vector_3          Construct_vector_3;
    // for postcondition checking
    typedef typename R::Ray_3                      Ray_3;
    
    typedef typename R::Has_on_3                   Has_on_3;
    typedef Point_triple_oriented_side_3<Self>     Oriented_side_3;
    typedef typename R::Do_intersect_3             Do_intersect_3;
    
    Construct_segment_3
    construct_segment_3_object() const
    { return Construct_segment_3(); }
    
    Construct_ray_3
    construct_ray_3_object() const
    { return Construct_ray_3(); }
    
    Construct_plane_3
    construct_plane_3_object() const
    { return Construct_plane_3(); }
    
    Construct_triangle_3
    construct_triangle_3_object() const
    { return Construct_triangle_3(); }
    
    Construct_centroid_3
    construct_centroid_3_object() const
    { return Construct_centroid_3(); }
    
    Construct_orthogonal_vector_3
    construct_orthogonal_vector_3_object() const
    { return Construct_orthogonal_vector_3(); }
    
    Collinear_3
    collinear_3_object() const
    { return Collinear_3(); }
    
    Coplanar_3
    coplanar_3_object() const
    { return Coplanar_3(); }
    
    Has_on_3
    has_on_3_object() const
    { return Has_on_3(); }
    
    Less_distance_to_point_3
    less_distance_to_point_3_object() const
    { return Less_distance_to_point_3(); }
    
    Has_on_positive_side_3
    has_on_positive_side_3_object() const
    { return Has_on_positive_side_3(); }
    
    Oriented_side_3
    oriented_side_3_object() const
    { return Oriented_side_3(); }
    
    Equal_3
    equal_3_object() const
    { return Equal_3(); }
    
    Do_intersect_3
    do_intersect_3_object() const
    { return Do_intersect_3(); }
    
    Less_signed_distance_to_plane_3
    less_signed_distance_to_plane_3_object() const
    { return Less_signed_distance_to_plane_3(); }
    
    Orientation_3
    orientation_3_object() const
    { return Orientation_3(); }
    
    Construct_vector_3
    construct_vector_3_object() const
    { return Construct_vector_3(); }
    
};

} // namespace CGAL


