//
//  PointGenerator.cpp
//  CGALViewer
//
//  Created by Paul Agron on 1/23/17.
//  Copyright © 2017 Paul Agron. All rights reserved.
//

#include "PointGenerator.hpp"
#include "Helpers.hpp"

#include <CGAL/centroid.h>

// Maybe we use this for clipping (see LLoyds algorithm)
#include <CGAL/Convex_hull_3/dual/halfspace_intersection_3.h>

#include <iostream>
#include <CGAL/Polyhedron_incremental_builder_3.h>
#include <CGAL/Nef_polyhedron_3.h>
#include <CGAL/IO/Nef_polyhedron_iostream_3.h>




typedef CGAL::Nef_polyhedron_3<adb::K> Nef_polyhedron;





using namespace std;


namespace adb {
    auto planesOfPoly(Polyhedron_3& p)->std::list<Plane> {
        std::list<Plane> res;
        
        for (auto facetH = p.facets_begin(); facetH != p.facets_end(); facetH++) {
            //      cout << "New facet: ";
            auto h = facetH->facet_begin();
            res.push_front( Plane( h->vertex()->point(), h->next()->vertex()->point(), h->next()->next()->vertex()->point()));
        }
        
        return res;
    }
    
    typedef CGAL::Polyhedron_3<K>::HalfedgeDS             HalfedgeDS;
    
    
    void testStuff() {
        
        /*
        CGAL::Polyhedron_3<K> P, Q, R;
        BuildCube<HalfedgeDS> cube;
        BuildTetra<HalfedgeDS> tet;
        P.delegate(tet);
        Q.delegate(cube);
        
        typedef CGAL::Nef_polyhedron_3<K> Nef_polyhedron;
        
        Nef_polyhedron N1(P);
        Nef_polyhedron N2(Q);
        
        Nef_polyhedron N3 = N1 * N2;
        
        auto check = P.is_closed() && Q.is_closed();
        if (check) {
            std::cout << "works" << std::endl;
        }
        CGAL_assertion( check );
        
        if(N3.is_simple()) {
            N3.convert_to_polyhedron(R);
            std::cout << R;
        }
        else
            std::cerr << "N3 is not a 2-manifold." << std::endl;
        
        
        */

    }
}



adb::PointGenerator::PointGenerator(unsigned pointCount)
{
    // will generate points in range:  (-cuberadius, cuberadius)
    int const pointsToGenerate = pointCount;
    int const cubeRadius = 10;
    int const expectedEpsilon = (2 * cubeRadius) / sqrt(pointsToGenerate);
    int const maxTryCount = 10000;
    
    CGAL::Random_points_in_cube_3<Point> gen(cubeRadius);
    for (int j=0, tryCount=0; j<pointsToGenerate && tryCount < maxTryCount; j++, gen++, tryCount++) {
        Point p = *gen;
        
        Neighbor_search search(tree, p, 1);
        
        Neighbor_search::iterator it = search.begin();
        if (it != search.end()) {
            
            auto dist = sqrt(CGAL::to_double(it->second));
            if (dist > expectedEpsilon)
                tree.insert(p);
            else
                j--;
        }
        else
        {
            tree.insert(p);
        }
        
        
        //cout << p << endl;
    }
    
    triangulation = Triangulation(tree.begin(), tree.end());


}



auto adb::PointGenerator::isNonHullVertex(Vertex_handle vH)->bool {
    vector<Cell_handle> handles;
    triangulation.incident_cells(vH, back_inserter(handles));
    

    for (auto c : handles) {
        if (triangulation.is_infinite(c)) {
            return false;
        }
    }
    
    return true;
    
}

auto adb::PointGenerator::innerVertices()->std::list<Vertex_handle> {
    list<Vertex_handle> result;
    for (auto vH = triangulation.finite_vertices_begin(); vH != triangulation.finite_vertices_end(); vH++) {
        // cout << "Cell (" << cellH->circumcenter() << ")" << endl;
       if (isNonHullVertex(vH))
            result.push_front(vH);
    }
    return result;
}

auto adb::PointGenerator::hullVertices()->std::list<Vertex_handle> {
    list<Vertex_handle> result;
    for (auto vH = triangulation.finite_vertices_begin(); vH != triangulation.finite_vertices_end(); vH++) {
        // cout << "Cell (" << cellH->circumcenter() << ")" << endl;
        if (!isNonHullVertex(vH))
            result.push_front(vH);
    }
    return result;
}

auto adb::PointGenerator::firstVoroCell()->Polyhedron_3 {
    Polyhedron_3 p;
    
    Vertex_handle v = innerVertices().front();
    
    vector<Cell_handle> handles;
    vector<Point> points;
    triangulation.incident_cells(v, back_inserter(handles));
    
    
    for (auto c : handles) {
        points.push_back(c->circumcenter());
    }
    
    CGAL::convex_hull_3(points.begin(), points.end(), p);
    
    return p;
}



namespace adb {

    // fascets of input poly aren't necessarily triangles so this is how we deal with it
//    void triangulatePolyhedron(Polyhedron_3& input, Polyhedron_3& output) {
//        CGAL_assertion( input.is_closed() );
//        Nef_polyhedron nef(input);
//        CGAL_assertion(nef.is_simple());
//        nef.convert_to_polyhedron(output);
//    }
    
    
    void triangulatePolyhedron_using_hull(Polyhedron_3& input, Polyhedron_3& output) {
        std::list<Point> points;
        for (auto v=input.vertices_begin(); v != input.vertices_end(); v++) {
            points.push_front(v->point());
        }
        
        CGAL::convex_hull_3(points.begin(), points.end(), output);
    }
    
}

namespace adb {
    static auto const plane1 = Plane(Point(0,0,10),Vector(0,0,1));
    static auto const plane2 = Plane(Point(10,0,0),Vector(1,0,0));
    static auto const plane3 = Plane(Point(0,10,0),Vector(0,1,0));
    
    static auto const plane11 = Plane(Point(0,0,-10),Vector(0,0,-1));
    static auto const plane22 = Plane(Point(-10,0,0),Vector(-1,0,0));
    static auto const plane33 = Plane(Point(0,-10,0),Vector(0,-1,0));
    
    static list<Plane> const boundary = { plane1, plane2, plane3, plane11, plane22, plane33 } ;
}


auto adb::PointGenerator::generateVoroCells()->list<Polyhedron_3> {
    list<Polyhedron_3> res;
    
    unsigned counter = 0;
    
    for (Vertex_handle v : innerVertices()) {
        Polyhedron_3 p;
        
        vector<Cell_handle> handles;
        vector<Point> points;
        triangulation.incident_cells(v, back_inserter(handles));
        
        
        for (auto c : handles) {
            points.push_back(c->circumcenter());
        }
        
        CGAL::convex_hull_3(points.begin(), points.end(), p);

        // intersect planes with the boundary
        list<Plane> planes = planesOfPoly(p);
        planes.insert(planes.begin(), boundary.begin(), boundary.end());
        
        Polyhedron_3 cell, triangulatedCell;
        CGAL::halfspace_intersection_3(planes.begin(), planes.end(), cell);
        triangulatePolyhedron_using_hull(cell, triangulatedCell);
        res.push_front(triangulatedCell);
        
        cout << counter++ << endl;
    }
    
    
#if 1
    list<Vertex_handle> hullVerts = hullVertices();
    
    for (Vertex_handle src : hullVertices()) {
        vector<Vertex_handle> neighbors;
        triangulation.finite_adjacent_vertices(src, back_inserter(neighbors));
        
        list<Plane> planes;
        
        CGAL_assertion( neighbors.size() > 0 );
        for (Vertex_handle dest : neighbors) {
            Vector v = dest->point() - src->point();
            Point midpoint = src->point() + (v * 0.5);
            Plane plane = Plane(midpoint,v);
            planes.push_front(plane);
        }
        
        // intersect planes with the boundary
        planes.insert(planes.begin(), boundary.begin(), boundary.end());
        
        Polyhedron_3 q, triangulated;
        CGAL::halfspace_intersection_3(planes.begin(),  planes.end(), q);
        
        triangulatePolyhedron_using_hull(q, triangulated);
        res.push_front(triangulated);
        
        cout << counter++ << endl;
    }
    
#endif

    cout << "Nef stage" << endl;
    counter = 0;
        
    list<Polyhedron_3> transformedCells;
    
    CGAL::Polyhedron_3<K> leftCube, rightCube, transformedHedron;
    BuildCube<HalfedgeDS> cubeBuilder;
    leftCube.delegate(cubeBuilder);
    rightCube.delegate(cubeBuilder);
    CGAL_assertion( leftCube.is_closed() );
    
//    Transformation rotate(ROTATION, sin(pi), cos(pi));
//    Transformation rational_rotate(ROTATION,Direction(1,1), 1, 100);
//    Transformation translate(TRANSLATION, Vector(-2, 0));
//    Transformation scale(SCALING, 3);
    
    Transform translateRight(CGAL::TRANSLATION, Vector(12, -2, 0));
    Transform translateLeft(CGAL::TRANSLATION, Vector(-12, -2, 0));
    
    std::transform( rightCube.points_begin(), rightCube.points_end(), rightCube.points_begin(), translateRight);
    std::transform( leftCube.points_begin(), leftCube.points_end(), leftCube.points_begin(), translateLeft);
    
    Nef_polyhedron nef_leftCube(leftCube);
    Nef_polyhedron nef_rightCube(rightCube);
    
    for (auto cell : res) {
        Nef_polyhedron nef_cell(cell);
        Nef_polyhedron intersected = (nef_cell - nef_leftCube) - nef_rightCube;
        
        if (intersected.is_simple())  {
            intersected.convert_to_polyhedron(transformedHedron);
            transformedCells.push_front(transformedHedron);
        }
        
        cout << counter++ << endl;
    }

    return transformedCells;
}




auto adb::PointGenerator::processVoroCell(Polyhedron_3& p, VoroCellRepresentation& outRep)->void
{
    int j=0;
    for (auto v=p.vertices_begin(); v != p.vertices_end(); v++, j++ ) {
      //  v->set_index(j);
        outRep.vertices.push_back(v->point());
//        cout << v->index() << ": " << v->point() << endl;
    }
    
    
    // if we wanted to compute centroid we could do
    // Point center = CGAL::centroid(outRep.vertices.begin(),outRep.vertices.end());


    
    for (auto facetH = p.facets_begin(); facetH != p.facets_end(); facetH++) {
  //      cout << "New facet: ";
        auto halfedgeH = facetH->facet_begin();
        CGAL_assertion( CGAL::circulator_size(halfedgeH) == 3);
        if (halfedgeH != NULL) {
            do {
                //cout << halfedgeH->vertex()->index() << " ";
                
                // This is very slow (quadratic time) since distance call is linear
                // but have to do it this way since C++ templates suck ( unable to construct
                // Polyhedron_3<K> from Polyhedron<K,My_stuff> easily)
                auto index = std::distance(p.vertices_begin(), halfedgeH->vertex());
                CGAL_assertion(index >= 0);
                outRep.triangle_indexes.push_back(static_cast<unsigned>(index));
//                outRep.triangle_indexes.push_back(halfedgeH->vertex()->index());
                
                //halfedgeH->vertex()->point();

                
            } while (++halfedgeH != facetH->facet_begin());
        }
        
        //cout << endl;
    }
}

auto adb::PointGenerator::triangulationEdges()->list<Edge_geom> {
    list<Edge_geom> result;
    
    
    for (auto edges = triangulation.finite_edges_begin(); edges != triangulation.finite_edges_end(); edges++) {
        
        auto edge = *edges;
        Cell_handle c = edge.first;
        
        
        
        Point p=c->vertex(edge.second)->point();
        Point q=c->vertex(edge.third)->point();
        
        auto geom = std::pair<Point,Point>(p,q);
        
        result.push_front(geom);
    }
    
    
    return result;
}



















