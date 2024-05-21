import 'package:flutter/material.dart';
import 'team.dart';

class TeamUp extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String id;
  final String height;
  final String weight;
  final List<String> types;

  TeamUp({
    required this.name,
    required this.imageUrl,
    required this.id,
    required this.height,
    required this.weight,
    required this.types,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Up'), // Título de la página
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$name is in your team!', // Mensaje de bienvenida
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Image.network(
              imageUrl,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              'ID: $id',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Height: $height',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Weight: $weight',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Types: ${types.join(", ")}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (TeamPage.team.length < 3) {
                  // Verifica si el Pokémon ya está en el equipo
                  bool isDuplicate =
                      TeamPage.team.any((pokemon) => pokemon['id'] == id);
                  if (!isDuplicate) {
                    // Llama al método addPokemonToTeam en team.dart y pasa los datos del Pokémon
                    TeamPage.addPokemonToTeam({
                      'name': name,
                      'imageUrl': imageUrl,
                      'id': id,
                      'height': height,
                      'weight': weight,
                      'types': types,
                    });
                    Navigator.push(
                      // Navega a la página del equipo después de agregar el Pokémon
                      context,
                      MaterialPageRoute(builder: (context) => TeamPage()),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Duplicate Pokemon!'),
                          content:
                              Text('This Pokemon is already in your team.'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); // Cerrar el diálogo
                                Navigator.popUntil(
                                    context,
                                    ModalRoute.withName(
                                        '/')); // Ir a la pantalla de inicio
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Team is full!'),
                        content:
                            Text('You can only have 3 Pokémon in your team.'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.popUntil(
                                  context, ModalRoute.withName('/'));
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
