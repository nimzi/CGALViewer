//
//  PointGenerator.hpp
//  CGALViewer
//
//  Created by Paul Agron on 1/23/17.
//  Copyright © 2017 Paul Agron. All rights reserved.
//

#pragma once

#include <list>
#include <cmath>

//#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Exact_predicates_exact_constructions_kernel.h>

//#include <CGAL/Simple_cartesian.h>

//#include <CGAL/Aff_transformation_3.h>
#include <CGAL/Orthogonal_k_neighbor_search.h>
#include <CGAL/Search_traits_3.h>
#include <CGAL/Triangulation_3.h>
#include <CGAL/Delaunay_triangulation_3.h>
#include <CGAL/Polyhedron_3.h>

#include <CGAL/convex_hull_3.h>
#include <CGAL/point_generators_3.h>

// A great example of doing similar things to what we are doing here:
//         https://github.com/CGAL/cgal/blob/master/Convex_hull_3/examples/Convex_hull_3/lloyd_algorithm.cpp

namespace adb {
    typedef CGAL::Exact_predicates_exact_constructions_kernel K;
   /// typedef CGAL::Simple_cartesian<double> K;
    
    typedef K::Point_3 Point;
    typedef K::Vector_3 Vector;
    typedef K::Triangle_3 Triangle;
    typedef K::Plane_3 Plane;
    typedef K::Direction_3 Direction;
    
    typedef K::Aff_transformation_3 Transform;
    typedef CGAL::Search_traits_3<K> TreeTraits;
    typedef CGAL::Orthogonal_k_neighbor_search<TreeTraits> Neighbor_search;
    typedef Neighbor_search::Tree Tree;
    
    
    typedef CGAL::Delaunay_triangulation_3<K> Triangulation;
    //typedef CGAL::Triangulation_3<K>      Triangulation;
    typedef Triangulation::Cell_handle    Cell_handle;
    typedef Triangulation::Vertex_handle  Vertex_handle;
    typedef Triangulation::Locate_type    Locate_type;
    //typedef Triangulation::Point          Point;
    
    
    typedef std::pair<Point,Point>     Edge_geom;
    
    
    
    // a list of vertices followed by a list of triangles
    class VoroCellRepresentation {
    public:
        std::vector<Point> vertices;
        std::vector<unsigned> triangle_indexes; // each tripple represents a triangle
    };
    
    
    // Customizing elements of my poly
    ////////////////////////////////////////////////////////////////
    template <class Refs>
    struct My_face : public CGAL::HalfedgeDS_face_base<Refs> {
        CGAL::Color color;
    };
    
    template <class T_Refs, class T_Point>
    struct CustomVertex :  public CGAL::HalfedgeDS_vertex_base<T_Refs, CGAL::Tag_true, T_Point>
    {
    private:
        typedef CGAL::HalfedgeDS_vertex_base<T_Refs, CGAL::Tag_true, T_Point> Base;
        
        bool m_processed;
        bool m_marked;
        int m_index;
        
    public:
        typedef typename Base::Point                                  Point;
        
        /*! Constructor */
        CustomVertex() : Base(), m_marked(false), m_index(0) {}
        
        CustomVertex(const Point & p) :
        Base(p), m_marked(false) {}
        
        //Point & point() { return Base::point(); }
        
        //const Point & point () const { return Base::point(); }
        
        void set_processed(bool processed) { m_processed = processed; }
        
        bool processed() const { return m_processed; } 
        
        void set_marked(bool marked) { m_marked = marked; } 
        
        bool marked() const { return m_marked; }
        
        void set_index(int i) { m_index = i; }
        
        int index() const { return m_index; }

    };
    
    
    
    // An items type using my face.
    struct My_items : public CGAL::Polyhedron_items_3 {
        template <class Refs, class Traits>
        struct Face_wrapper {
            typedef My_face<Refs> Face;
        };
        
        template < class Refs, class Traits>
        struct Vertex_wrapper {
            typedef typename Traits::Point_3 Point;
            typedef CustomVertex<Refs, Point> Vertex;
        };
        
    };
    
    //typedef CGAL::Polyhedron_3<K,My_items>         Polyhedron_3;
    typedef CGAL::Polyhedron_3<K>      Polyhedron_3;
    
    ///////////////////////////////////////////////////////////////////////////////////
    
    
    class PointGenerator {
    public:
        PointGenerator(unsigned pointCount);
        
        auto points()->std::list<Point> {
            std::list<Point> points(tree.begin(), tree.end());
            return points;
        }
        
        auto triangulationEdges()->std::list<Edge_geom>;
        
        auto isNonHullVertex(Vertex_handle v)->bool;
        
        // non-hull verts
        auto innerVertices()->std::list<Vertex_handle>;
        
        // verts on hull
        auto hullVertices()->std::list<Vertex_handle>;
        
        auto firstVoroCell()->Polyhedron_3;
        auto generateVoroCells()->std::list<Polyhedron_3>;
        auto processVoroCell(Polyhedron_3& p, VoroCellRepresentation& outRep)->void;
    private:
        Tree tree;
        Triangulation triangulation;
        //unsigned _pointCount;
    };
    
    
    void testStuff();
}


////  Polyhedron customization example
//
//
//template <class T_Refs, class T_Point>
//class customVertex :
//public CGAL::HalfedgeDS_vertex_base<T_Refs, CGAL::Tag_true, T_Point>
//{
//private:
//    typedef CGAL::HalfedgeDS_vertex_base<T_Refs, CGAL::Tag_true, T_Point> Base;
//    
//    bool m_processed;
//    
//    bool m_marked;
//    
//public:
//    typedef typename Base::Point                                  Point;
//    
//    /*! Constructor */
//    customVertex() : Base(), m_marked(false) {}
//    
//    customVertex(const Point & p) :
//    Base(p), m_marked(false) {}
//    
//    Point & point() { return Base::point(); }
//    
//    const Point & point () const { return Base::point(); }
//    
//    void set_processed(bool processed) { m_processed = processed; }
//    
//    bool processed() const { return m_processed; }
//    
//    void set_marked(bool marked) { m_marked = marked; }
//    
//    bool marked() const { return m_marked; }
//};
//
//
//struct Wrappers:public CGAL::Polyhedron_items_3 {
//    
//    template < class Refs, class Traits>
//    struct Vertex_wrapper {
//        typedef typename Traits::Point_3 Point;
//        typedef customVertex< Refs, Point> Vertex;
//    };
//    template < class Refs, class Traits>
//    struct Halfedge_wrapper {
//        typedef CGAL::HalfedgeDS_halfedge_base<Refs>                Halfedge;
//    };
//    template < class Refs, class Traits>
//    struct Face_wrapper {
//        typedef typename Traits::Plane_3 Plane;
//        typedef CGAL::HalfedgeDS_face_base< Refs, CGAL::Tag_true, Plane>   Face;
//    };
//    
//};
//
//
//
//template<class HDS>
//class polyhedron_builder : public CGAL::Modifier_base<HDS> {
//public:
//    std::list<Point_3> &coords;
//    std::list<size_t>    &tris;
//    polyhedron_builder( std::list<Point_3> &_coords, std::list<size_t> &_tris ) : coords(_coords), tris(_tris) {}
//    void operator()( HDS& hds) {
//        typedef typename HDS::Vertex   Vertex;
//        typedef typename Vertex::Point Point;
//        
//        // create a cgal incremental builder
//        CGAL::Polyhedron_incremental_builder_3<HDS> B( hds, true);
//        B.begin_surface( coords.size()/3, tris.size()/3 );
//        
//        // add the polyhedron vertices
//        for (std::list<Point_3>::const_iterator iterator = coords.begin(), end = coords.end(); iterator != end; iterator++) {
//            B.add_vertex(*iterator);
//        }
//        
//        
//        // add the polyhedron triangles
//        for (std::list<size_t>::const_iterator iterator = tris.begin(), end = tris.end(); iterator != end; iterator++) {
//            B.begin_facet();
//            B.add_vertex_to_facet(*iterator);
//            iterator++;
//            B.add_vertex_to_facet(*iterator);
//            iterator++; 
//            B.add_vertex_to_facet(*iterator); 
//            B.end_facet(); 
//        } 
//        
//        // finish up the surface 
//        B.end_surface(); 
//    } 
//}; 
