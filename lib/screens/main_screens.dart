import 'package:citytourscartagena/screens/agencias_view.dart';
import 'package:citytourscartagena/screens/colaboradores_view.dart';
import 'package:citytourscartagena/screens/reservas_view.dart';
import 'package:flutter/material.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ReservasView(),
    const AgenciasView(),
    const ColaboradoresView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Agencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Colaboradores',
          ),
        ],
      ),
    );
  }
}
