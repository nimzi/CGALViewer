//
//  main.m
//  CGALViewer
//
//  Created by Paul Agron on 1/13/17.
//  Copyright © 2017 Paul Agron. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PointGenerator.hpp"



namespace adb {
	int kickoff();
}

int main(int argc, const char * argv[]) {
	
    adb::testStuff();
	//adb::kickoff();
	
	return NSApplicationMain(argc, argv);
}

//
//#include <iostream>
//#include <CGAL/Exact_predicates_exact_constructions_kernel.h>
//#include <sstream>
//typedef CGAL::Exact_predicates_exact_constructions_kernel Kernel;
//typedef Kernel::Point_2 Point_2;
//typedef Kernel::Point_3 Point_3;
//
//#include <CGAL/point_generators_d.h>
//
//int kickoff()
//{
//	Point_2 p(0, 0.3), q, r(2, 0.9);
//	{
//		q  = Point_2(1, 0.6);
//		std::cout << (CGAL::collinear(p,q,r) ? "collinear\n" : "not collinear\n");
//	}
//
//	{
//		std::istringstream input("0 0.3   1 0.6   2 0.9");
//		input >> p >> q >> r;
//		std::cout << (CGAL::collinear(p,q,r) ? "collinear\n" : "not collinear\n");
//	}
//
//	{
//		q = CGAL::midpoint(p,r);
//		std::cout << (CGAL::collinear(p,q,r) ? "collinear\n" : "not collinear\n");
//	}
//
//	return 0;
//}


//#include <CGAL/K_neighbor_search.h>
//#include <CGAL/Search_traits_d.h>
//
//#include <CGAL/Manhattan_distance_iso_box_point.h>
//

//int random_points()
//{
//	//CGAL::Random_points_in_cube_3<Point_3> jj;
//	//typedef CGAL::Manhattan_distance_iso_box_point<Kernel> Distance;
//	typedef CGAL::Euclidean_distance<Kernel> Distance;
//	typedef CGAL::K_neighbor_search<Kernel, Distance> Neighbor_search;
//
//
//
//	typedef Neighbor_search::Tree Tree;
//
//	Tree tree;
//	Point_3 pp(0.1,0.1,0.1,0.1);
//
//	Neighbor_search N1(tree, pp, 5, 10.0, false); // eps=10.0, nearest=false
//
//
//
//
//
//
//
//
//
//
//
//	return 0;
//}



#if 0

#include <CGAL/Simple_cartesian.h>
#include <CGAL/point_generators_3.h>
#include <CGAL/Orthogonal_k_neighbor_search.h>
#include <CGAL/Search_traits_3.h>
#include <list>
#include <cmath>


namespace adb {
	
    typedef CGAL::Simple_cartesian<double> K;
	typedef K::Point_3 Point;
	typedef K::Vector_3 Vector;
	typedef K::Aff_transformation_3 Transform;
	typedef CGAL::Search_traits_3<K> TreeTraits;
	typedef CGAL::Orthogonal_k_neighbor_search<TreeTraits> Neighbor_search;
	typedef Neighbor_search::Tree Tree;
	
	
	int kickoff() {
		using namespace std;
		
		
		
		const unsigned int N = 1;
		std::list<Point> points;
		points.push_back(Point(0,0,0));
		Tree tree(points.begin(), points.end());
		
		//tree.insert(<#const Point_d &p#>)
	
		Point query(0,0,0);
		// Initialize the search structure, and search all N points
		Neighbor_search search(tree, query, N);
		// report the N nearest neighbors and their distance
		// This should sort all N points by increasing distance from origin
		for(Neighbor_search::iterator it = search.begin(); it != search.end(); ++it){
			cout << it->first << " "<< sqrt(it->second) << endl;
		}
		
		
		
		CGAL::Random_points_in_cube_3<Point> gen;
		
		Point aa = *gen;
		
		//	Vector_3 bb = aa - CGAL::ORIGIN;
		//	bb * Vector_3(10,10,10);
		//
		//	Point_3 cc = CGAL::ORIGIN + bb;
		
		Transform t(5,0,0,  0, 10, 0,  0, 0, 100);
		
		Point jj = t(aa);
		
		cout << aa << " becomes " << jj;
		
		return 0;
	}
	
}

#endif





