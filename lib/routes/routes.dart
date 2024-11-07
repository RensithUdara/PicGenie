import 'package:flutter/material.dart';
import 'package:picgenie/routes/routes_names.dart';
import 'package:picgenie/view/home_view.dart';

class Routes {
  static Route<dynamic> generatedRoutes(RouteSettings setting) {
    switch (setting.name) {
      case RoutesName.homeView:
        return _createRoute(const HomeView());
      default:
        return _createRoute(
          const Scaffold(
            body: Center(child: Text("Route Not Found")),
          ),
        );
    }
  }

  static PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut; 

        var slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0), 
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        var fadeAnimation = Tween<double>(
          begin: 0.0, 
          end: 1.0, 
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration:
          const Duration(milliseconds: 700), 
    );
  }
}
