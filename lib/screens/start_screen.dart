import 'package:flutter/material.dart';
import '../widgets/admob_banner.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xffaeefff), Color(0xffeef9ff)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bubble Pop',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
                child: const Text('start', style: TextStyle(fontSize: 28)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdmobBanner(),
    );
  }
}